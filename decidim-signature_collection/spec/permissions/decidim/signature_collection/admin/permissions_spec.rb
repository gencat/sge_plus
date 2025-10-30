# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::Admin::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { create(:user, organization:) }
  let(:organization) { create(:organization) }
  let(:candidacy) { create(:candidacy, organization:) }
  let(:context) { { candidacy: } }
  let(:permission_action) { Decidim::PermissionAction.new(**action) }
  let(:candidacies_settings) { create(:candidacies_settings, organization:) }
  let(:action) do
    { scope: :admin, action: action_name, subject: action_subject }
  end

  shared_examples "checks candidacy state" do |name, valid_trait, invalid_trait|
    let(:action_name) { name }

    context "when candidacy is #{valid_trait}" do
      let(:candidacy) { create(:candidacy, valid_trait, organization:) }

      it { is_expected.to be true }
    end

    context "when candidacy is not #{valid_trait}" do
      let(:candidacy) { create(:candidacy, invalid_trait, organization:) }

      it { is_expected.to be false }
    end
  end

  shared_examples "candidacy committee action" do
    let(:action_subject) { :candidacy_committee_member }

    context "when indexing" do
      let(:action_name) { :index }

      it { is_expected.to be true }
    end

    context "when approving" do
      let(:action_name) { :approve }
      let(:context) { { candidacy:, request: } }

      context "when request is not accepted yet" do
        let(:request) { create(:candidacies_committee_member, :requested, candidacy:) }

        it { is_expected.to be true }
      end

      context "when request is already accepted" do
        let(:request) { create(:candidacies_committee_member, :accepted, candidacy:) }

        it { is_expected.to be false }
      end
    end

    context "when revoking" do
      let(:action_name) { :revoke }
      let(:context) { { candidacy:, request: } }

      context "when request is not revoked yet" do
        let(:request) { create(:candidacies_committee_member, :accepted, candidacy:) }

        it { is_expected.to be true }
      end

      context "when request is already revoked" do
        let(:request) { create(:candidacies_committee_member, :rejected, candidacy:) }

        it { is_expected.to be false }
      end
    end

    context "when any other condition" do
      let(:action_name) { :foo }

      it_behaves_like "permission is not set"
    end
  end

  context "when the action is not for the admin part" do
    let(:action) do
      { scope: :public, action: :foo, subject: :candidacy }
    end

    it_behaves_like "permission is not set"
  end

  context "when user is not given" do
    let(:user) { nil }
    let(:action) do
      { scope: :admin, action: :foo, subject: :candidacy }
    end

    it_behaves_like "permission is not set"
  end

  context "when checking access to space area" do
    let(:action) do
      { scope: :admin, action: :enter, subject: :space_area }
    end
    let(:context) { { space_name: :candidacies } }

    context "when user created an candidacy" do
      let(:candidacy) { create(:candidacy, author: user, organization:) }

      before { candidacy }

      it { is_expected.to be true }
    end

    context "when user promoted an candidacy" do
      before do
        create(:candidacies_committee_member, candidacy:, user:)
      end

      it { is_expected.to be true }
    end

    context "when user is admin" do
      let(:user) { create(:user, :admin, organization:) }

      it { is_expected.to be true }
    end

    context "when space name is not set" do
      let(:context) { {} }

      it_behaves_like "permission is not set"
    end
  end

  context "when user is a member of the candidacy" do
    before do
      create(:candidacies_committee_member, candidacy:, user:)
    end

    it_behaves_like "candidacy committee action"

    context "when managing candidacies" do
      let(:action_subject) { :candidacy }

      context "when reading" do
        let(:action_name) { :read }

        before do
          allow(Decidim::SignatureCollection).to receive(:print_enabled).and_return(print_enabled)
        end

        context "when print is disabled" do
          let(:print_enabled) { false }

          it { is_expected.to be false }
        end

        context "when print is enabled" do
          let(:print_enabled) { true }

          it { is_expected.to be true }
        end
      end

      context "when updating" do
        let(:action_name) { :update }

        context "when candidacy is created" do
          let(:candidacy) { create(:candidacy, :created, organization:) }

          it { is_expected.to be true }
        end

        context "when candidacy is not created" do
          it { is_expected.to be false }
        end
      end

      context "when sending to technical validation" do
        let(:action_name) { :send_to_technical_validation }

        context "when candidacy is created" do
          let(:candidacy) { create(:candidacy, :created, organization:) }

          context "when candidacy is authored by a user group" do
            let(:user_group) { create(:user_group, organization: user.organization, users: [user]) }

            before do
              candidacy.update(decidim_user_group_id: user_group.id)
            end

            it { is_expected.to be true }
          end

          context "when candidacy has enough approved members" do
            before do
              allow(candidacy).to receive(:enough_committee_members?).and_return(true)
            end

            it { is_expected.to be true }
          end

          context "when candidacy has not enough approved members" do
            before do
              allow(candidacy).to receive(:enough_committee_members?).and_return(false)
            end

            it { is_expected.to be false }
          end
        end

        context "when candidacy is discarded" do
          let(:candidacy) { create(:candidacy, :discarded, organization:) }

          it { is_expected.to be true }
        end

        context "when candidacy is not created or discarded" do
          it { is_expected.to be false }
        end
      end

      context "when editing" do
        let(:action_name) { :edit }

        it { is_expected.to be true }
      end

      context "when previewing" do
        let(:action_name) { :preview }

        it { is_expected.to be true }
      end

      context "when managing memberships" do
        let(:action_name) { :manage_membership }

        it { is_expected.to be true }
      end

      context "when reading an candidacies settings" do
        let(:action_subject) { :candidacies_settings }
        let(:action_name) { :update }

        it { is_expected.to be false }
      end

      context "when any other action" do
        let(:action_name) { :foo }

        it { is_expected.to be false }
      end
    end

    context "when managing attachments" do
      let(:action_subject) { :attachment }

      shared_examples "attached to an candidacy" do |name|
        context "when action is #{name}" do
          let(:action_name) { name }
          let(:context) { { candidacy:, attachment: } }

          context "when attached to an candidacy" do
            let(:attachment) { create(:attachment, attached_to: candidacy) }

            it { is_expected.to be true }
          end

          context "when attached to something else" do
            let(:attachment) { create(:attachment) }

            it { is_expected.to be false }
          end
        end
      end

      context "when reading" do
        let(:action_name) { :read }

        it { is_expected.to be true }
      end

      context "when creating" do
        let(:action_name) { :create }

        it { is_expected.to be true }
      end

      it_behaves_like "attached to an candidacy", :update
      it_behaves_like "attached to an candidacy", :destroy
    end
  end

  context "when user is admin" do
    let(:user) { create(:user, :admin, organization:) }

    it_behaves_like "candidacy committee action"

    context "when managing attachments" do
      let(:action_subject) { :attachment }
      let(:action_name) { :foo }

      it { is_expected.to be true }
    end

    context "when managing candidacy types" do
      let(:action_subject) { :candidacy_type }

      context "when destroying" do
        let(:action_name) { :destroy }
        let(:candidacy_type) { create(:candidacies_type) }
        let(:organization) { candidacy_type.organization }
        let(:context) { { candidacy_type: } }

        before do
          allow(candidacy_type).to receive(:scopes).and_return(scopes)
        end

        context "when its scopes are empty" do
          let(:scopes) do
            [
              double(candidacies: [])
            ]
          end

          it { is_expected.to be true }
        end

        context "when its scopes are not empty" do
          let(:scopes) do
            [
              double(candidacies: [1, 2, 3])
            ]
          end

          it { is_expected.to be false }
        end
      end

      context "when any random action" do
        let(:action_name) { :foo }

        it { is_expected.to be true }
      end
    end

    context "when managing candidacy type scopes" do
      let(:action_subject) { :candidacy_type_scope }

      context "when destroying" do
        let(:action_name) { :destroy }
        let(:scope) { create(:candidacies_type_scope) }
        let(:context) { { candidacy_type_scope: scope } }

        before do
          allow(scope).to receive(:candidacies).and_return(candidacies)
        end

        context "when it has no candidacies" do
          let(:candidacies) do
            []
          end

          it { is_expected.to be true }
        end

        context "when it has some candidacies" do
          let(:candidacies) do
            [1, 2, 3]
          end

          it { is_expected.to be false }
        end
      end

      context "when any random action" do
        let(:action_name) { :foo }

        it { is_expected.to be true }
      end
    end

    context "when managing candidacies" do
      let(:action_subject) { :candidacy }

      context "when printing" do
        let(:action_name) { :print }

        before do
          allow(Decidim::SignatureCollection).to receive(:print_enabled).and_return(print_enabled)
        end

        context "when print is disabled" do
          let(:print_enabled) { false }

          it { is_expected.to be false }
        end

        context "when print is enabled" do
          let(:print_enabled) { true }

          it { is_expected.to be true }
        end
      end

      context "when reading" do
        let(:action_name) { :read }

        context "when print is enabled" do
          let(:print_enabled) { true }

          it { is_expected.to be true }
        end
      end

      it_behaves_like "checks candidacy state", :publish, :validating, :open
      it_behaves_like "checks candidacy state", :unpublish, :open, :validating
      it_behaves_like "checks candidacy state", :discard, :validating, :open
      it_behaves_like "checks candidacy state", :export_votes, :offline, :online
      it_behaves_like "checks candidacy state", :export_pdf_signatures, :open, :validating

      context "when accepting the candidacy" do
        let(:action_name) { :accept }
        let(:candidacy) { create(:candidacy, organization:, signature_end_date: 2.days.ago) }
        let(:goal_reached) { true }

        before do
          allow(candidacy).to receive(:supports_goal_reached?).and_return(goal_reached)
        end

        it { is_expected.to be true }

        context "when the candidacy is not published" do
          let(:candidacy) { create(:candidacy, :validating, organization:) }

          it { is_expected.to be false }
        end

        context "when the candidacy signature time is not finished" do
          let(:candidacy) { create(:candidacy, signature_end_date: 2.days.from_now, organization:) }

          it { is_expected.to be false }
        end

        context "when the candidacy percentage is not complete" do
          let(:goal_reached) { false }

          it { is_expected.to be false }
        end
      end

      context "when rejecting the candidacy" do
        let(:action_name) { :reject }
        let(:candidacy) { create(:candidacy, organization:, signature_end_date: 2.days.ago) }
        let(:goal_reached) { false }

        before do
          allow(candidacy).to receive(:supports_goal_reached?).and_return(goal_reached)
        end

        it { is_expected.to be true }

        context "when the candidacy is not published" do
          let(:candidacy) { create(:candidacy, :validating, organization:) }

          it { is_expected.to be false }
        end

        context "when the candidacy signature time is not finished" do
          let(:candidacy) { create(:candidacy, signature_end_date: 2.days.from_now, organization:) }

          it { is_expected.to be false }
        end

        context "when the candidacy percentage is complete" do
          let(:goal_reached) { true }

          it { is_expected.to be false }
        end
      end
    end

    context "when reading an candidacies settings" do
      let(:action_subject) { :candidacies_settings }
      let(:action_name) { :update }

      it { is_expected.to be true }
    end
  end

  context "when any other condition" do
    let(:action) do
      { scope: :admin, action: :foo, subject: :bar }
    end

    it_behaves_like "permission is not set"
  end
end
