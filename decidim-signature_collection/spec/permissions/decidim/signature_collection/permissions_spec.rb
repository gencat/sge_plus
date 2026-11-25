# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { create(:user, organization:) }
  let(:organization) { create(:organization) }
  let(:candidacy) { create(:candidacy, organization:) }
  let(:context) { {} }
  let(:permission_action) { Decidim::PermissionAction.new(**action) }

  shared_examples "votes permissions" do
    let(:organization) { create(:organization, available_authorizations: authorizations) }
    let(:authorizations) { %w(dummy_authorization_handler another_dummy_authorization_handler) }
    let(:candidacy) { create(:candidacy, organization:) }
    let(:context) do
      { candidacy: }
    end
    let(:votes_enabled?) { true }

    before do
      allow(candidacy).to receive(:votes_enabled?).and_return(votes_enabled?)
    end

    context "when candidacy has votes disabled" do
      let(:votes_enabled?) { false }

      it { is_expected.to be false }
    end

    context "when the candidacy type has permissions to vote" do
      before do
        candidacy.type.create_resource_permission(
          permissions: {
            "vote" => {
              "authorization_handlers" => {
                "dummy_authorization_handler" => { "options" => {} },
                "another_dummy_authorization_handler" => { "options" => {} }
              }
            }
          }
        )
      end

      context "when user is fully verified" do
        before do
          create(:authorization, name: "dummy_authorization_handler", user:, granted_at: 2.seconds.ago)
          create(:authorization, name: "another_dummy_authorization_handler", user:, granted_at: 2.seconds.ago)
        end

        it { is_expected.to be true }
      end
    end
  end

  context "when the action is for the admin part" do
    let(:action) do
      { scope: :admin, action: :foo, subject: :candidacy }
    end
    let(:user) { create(:user, :admin, organization:) }

    it_behaves_like "delegates permissions to", Decidim::SignatureCollection::Admin::Permissions

    context "when accessing another participatory space" do
      let(:action) do
        { scope: :admin, action: :enter, subject: :space_area }
      end
      let(:context) do
        { space_name: :candidacies, current_participatory_space: create(:participatory_process, organization:) }
      end

      it { is_expected.to be true }
    end
  end

  context "when reading an candidacy" do
    let(:candidacy) { create(:candidacy, :discarded, organization:) }
    let(:action) do
      { scope: :public, action: :read, subject: :candidacy }
    end
    let(:context) do
      { candidacy: }
    end

    context "when candidacy is open" do
      let(:candidacy) { create(:candidacy, :open, organization:) }

      it { is_expected.to be true }
    end

    context "when candidacy is rejected" do
      let(:candidacy) { create(:candidacy, :rejected, organization:) }

      it { is_expected.to be true }
    end

    context "when candidacy is accepted" do
      let(:candidacy) { create(:candidacy, :accepted, organization:) }

      it { is_expected.to be true }
    end

    context "when user is admin" do
      let(:user) { create(:user, :admin, organization:) }

      it { is_expected.to be true }
    end

    context "when user is author of the candidacy" do
      let(:candidacy) { create(:candidacy, author: user, organization:) }

      it { is_expected.to be true }
    end

    context "when user is committee member of the candidacy" do
      before do
        create(:candidacies_committee_member, candidacy:, user:)
      end

      it { is_expected.to be true }
    end

    context "when any other condition" do
      it { is_expected.to be false }
    end
  end

  context "when listing committee members of the candidacy as author" do
    let(:candidacy) { create(:candidacy, organization:, author: user) }
    let(:action) do
      { scope: :public, action: :index, subject: :candidacy_committee_member }
    end
    let(:context) do
      { candidacy: }
    end

    it { is_expected.to be true }
  end

  context "when approving committee member of the candidacy as author" do
    let(:candidacy) { create(:candidacy, organization:, author: user) }
    let(:action) do
      { scope: :public, action: :approve, subject: :candidacy_committee_member }
    end
    let(:context) do
      { candidacy: }
    end

    it { is_expected.to be true }
  end

  context "when revoking committee member of the candidacy as author" do
    let(:candidacy) { create(:candidacy, organization:, author: user) }
    let(:action) do
      { scope: :public, action: :revoke, subject: :candidacy_committee_member }
    end
    let(:context) do
      { candidacy: }
    end

    it { is_expected.to be true }
  end

  context "when sending candidacy to technical validation as author" do
    let(:candidacy) { create(:candidacy, state: :created, organization:) }
    let(:action) do
      { scope: :public, action: :send_to_technical_validation, subject: :candidacy }
    end
    let(:context) do
      { candidacy: }
    end

    it { is_expected.to be true }
  end

  context "when managing an candidacy" do
    let(:action_subject) { :candidacy }

    context "when printing" do
      let(:action_name) { :print }
      let(:action) do
        { scope: :public, action: :print, subject: :candidacy }
      end
      let(:context) do
        { candidacy: }
      end

      before do
        allow(Decidim::SignatureCollection).to receive(:print_enabled).and_return(true)
      end

      context "when user is a committee member" do
        let(:candidacy) { create(:candidacy, :created, organization:) }

        before do
          create(:candidacies_committee_member, candidacy:, user:)
        end

        it { is_expected.to be true }
      end

      context "when user is not an candidacy author" do
        let(:candidacy) { create(:candidacy, :created, organization:) }

        it { is_expected.to be false }
      end

      context "when user is admin" do
        let(:user) { create(:user, :admin, organization:) }
        let(:candidacy) { create(:candidacy, :created, author: user, organization:) }

        it { is_expected.to be true }
      end
    end

    context "when editing" do
      let(:action_name) { :edit }
      let(:action) do
        { scope: :public, action: :edit, subject: :candidacy }
      end
      let(:context) do
        { candidacy: }
      end

      context "when candidacy is not created" do
        let(:candidacy) { create(:candidacy, author: user, organization:) }

        it { is_expected.to be false }
      end

      context "when user is a committee member" do
        let(:candidacy) { create(:candidacy, :created, organization:) }

        before do
          create(:candidacies_committee_member, candidacy:, user:)
        end

        it { is_expected.to be true }
      end

      context "when user is not an candidacy author" do
        let(:candidacy) { create(:candidacy, :created, organization:) }

        it { is_expected.to be false }
      end

      context "when user is admin" do
        let(:user) { create(:user, :admin, organization:) }
        let(:candidacy) { create(:candidacy, :created, author: user, organization:) }

        it { is_expected.to be true }
      end
    end

    context "when updating" do
      let(:action_name) { :update }
      let(:action) do
        { scope: :public, action: :edit, subject: :candidacy }
      end
      let(:context) do
        { candidacy: }
      end

      context "when candidacy is not created" do
        let(:candidacy) { create(:candidacy, organization:) }

        it { is_expected.to be false }
      end

      context "when user is a committee member" do
        let(:candidacy) { create(:candidacy, :created, organization:) }

        before do
          create(:candidacies_committee_member, user:, candidacy:)
        end

        it { is_expected.to be true }
      end

      context "when user is not an candidacy author" do
        let(:candidacy) { create(:candidacy, :created, organization:) }

        it { is_expected.to be false }
      end

      context "when user is admin" do
        let(:user) { create(:user, :admin, organization:) }
        let(:candidacy) { create(:candidacy, :created, author: user, organization:) }

        it { is_expected.to be true }
      end
    end
  end

  context "when requesting membership to an candidacy" do
    let(:action) do
      { scope: :public, action: :request_membership, subject: :candidacy }
    end
    let(:candidacy) { create(:candidacy, :discarded, organization:) }
    let(:context) do
      { candidacy: }
    end

    context "when candidacy is open" do
      let(:candidacy) { create(:candidacy, :open, organization:) }

      it { is_expected.to be false }
    end

    context "when candidacy is not open" do
      context "when user is member" do
        let(:candidacy) { create(:candidacy, :discarded, author: user, organization:) }

        it { is_expected.to be false }
      end

      context "when user is not a member" do
        let(:candidacy) { create(:candidacy, :discarded, organization:) }

        it { is_expected.to be false }

        context "when authorizations are not required" do
          before do
            allow(Decidim::SignatureCollection)
              .to receive(:do_not_require_authorization)
              .and_return(true)
          end

          it { is_expected.to be true }
        end

        context "when user is authorized" do
          before do
            create(:authorization, :granted, user:)
          end

          it { is_expected.to be true }
        end

        context "when user is not connected" do
          let(:user) { nil }

          it { is_expected.to be true }
        end
      end
    end
  end

  context "when voting an candidacy" do
    it_behaves_like "votes permissions" do
      let(:action) do
        { scope: :public, action: :vote, subject: :candidacy }
      end

      context "when user belongs to another organization" do
        let(:user) { create(:user) }

        it { is_expected.to be false }
      end
    end
  end

  context "when signing an candidacy" do
    it_behaves_like "votes permissions" do
      let(:action) do
        { scope: :public, action: :sign_candidacy, subject: :candidacy }
      end
    end
  end

  context "when unvoting an candidacy" do
    let(:action) do
      { scope: :public, action: :unvote, subject: :candidacy }
    end
    let(:candidacy) { create(:candidacy, organization:) }
    let(:context) do
      { candidacy: }
    end
    let(:votes_enabled?) { true }

    before do
      allow(candidacy).to receive(:votes_enabled?).and_return(votes_enabled?)
    end

    context "when candidacy has votes disabled" do
      let(:votes_enabled?) { false }

      it { is_expected.to be false }
    end

    context "when candidacy has unvotes disabled" do
      before do
        candidacy.type.update!(undo_online_signatures_enabled: false)
      end

      it { is_expected.to be false }
    end

    context "when user belongs to another organization" do
      let(:user) { create(:user) }

      it { is_expected.to be false }
    end

    # Votes no longer have an author (removed in 20251222131109), so the votes of the user cannot be found.
    context "when candidacy accepts unvotes" do
      it "raises an error" do
        expect(candidacy).to be_accepts_online_unvotes
        expect { subject }.to raise_error(ActiveRecord::StatementInvalid, /UndefinedColumn/)
      end
    end
  end

  describe "exporting candidacy files" do
    let(:export_candidacy) { create(:candidacy, :accepted, organization:) }
    let(:context) { { candidacy: export_candidacy } }

    shared_examples "allows only admin author committee" do |action_name|
      let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: action_name, subject: :candidacy) }

      context "when user is admin" do
        let(:user) { create(:user, :admin, organization:) }

        it { is_expected.to be true }
      end

      context "when user is author" do
        let(:user) { export_candidacy.author }

        it { is_expected.to be true }
      end

      context "when user is committee member" do
        let(:user) { create(:user, organization:) }

        before { create(:candidacies_committee_member, candidacy: export_candidacy, user:) }

        it { is_expected.to be true }
      end

      context "when user is a regular user" do
        let(:user) { create(:user, organization:) }

        it { is_expected.to be false }
      end

      context "when user belongs to another organization" do
        let(:user) { create(:user) }

        it { is_expected.to be false }
      end
    end

    describe "PDF signatures export" do
      it_behaves_like "allows only admin author committee", :export_pdf_signatures
    end

    describe "XML signatures export" do
      it_behaves_like "allows only admin author committee", :export_xml_signatures
    end

    describe "votes export" do
      it_behaves_like "allows only admin author committee", :export_votes
    end

    describe "edge conditions for export permissions" do
      context "when candidacy is created (should be blocked for pdf/xml)" do
        let(:export_candidacy) { create(:candidacy, :created, organization:) }

        context "when exporting pdf signatures" do
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_pdf_signatures, subject: :candidacy) }

          context "when user is author" do
            let(:user) { export_candidacy.author }

            it { is_expected.to be false }
          end

          context "when user is admin" do
            let(:user) { create(:user, :admin, organization:) }

            it { is_expected.to be false }
          end

          context "when user is committee member" do
            let(:user) { create(:user, organization:) }

            before { create(:candidacies_committee_member, candidacy: export_candidacy, user:) }

            it { is_expected.to be false }
          end
        end

        context "when exporting xml signatures" do
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_xml_signatures, subject: :candidacy) }

          context "when user is author" do
            let(:user) { export_candidacy.author }

            it { is_expected.to be false }
          end

          context "when user is admin" do
            let(:user) { create(:user, :admin, organization:) }

            it { is_expected.to be false }
          end

          context "when user is committee member" do
            let(:user) { create(:user, organization:) }

            before { create(:candidacies_committee_member, candidacy: export_candidacy, user:) }

            it { is_expected.to be false }
          end
        end
      end

      context "when candidacy is rejected (allowed for pdf/xml)" do
        let(:export_candidacy) { create(:candidacy, :rejected, organization:) }

        context "when exporting pdf signatures" do
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_pdf_signatures, subject: :candidacy) }

          context "when user is author" do
            let(:user) { export_candidacy.author }

            it { is_expected.to be true }
          end

          context "when user is admin" do
            let(:user) { create(:user, :admin, organization:) }

            it { is_expected.to be true }
          end
        end

        context "when exporting xml signatures" do
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_xml_signatures, subject: :candidacy) }

          context "when user is author" do
            let(:user) { export_candidacy.author }

            it { is_expected.to be true }
          end

          context "when user is admin" do
            let(:user) { create(:user, :admin, organization:) }

            it { is_expected.to be true }
          end
        end
      end

      context "when votes export signature_type variations" do
        context "when signature_type is offline (blocked)" do
          let(:export_candidacy) { create(:candidacy, :accepted, :offline, organization:) }
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_votes, subject: :candidacy) }
          let(:user) { export_candidacy.author }

          it { is_expected.to be false }
        end

        context "when signature_type is online (allowed)" do
          let(:export_candidacy) { create(:candidacy, :accepted, :online, organization:) }
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_votes, subject: :candidacy) }
          let(:user) { export_candidacy.author }

          it { is_expected.to be true }
        end

        context "when signature_type is any (allowed)" do
          let(:export_candidacy) { create(:candidacy, :accepted, organization:, signature_type: "any") }
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_votes, subject: :candidacy) }
          let(:user) { export_candidacy.author }

          it { is_expected.to be true }
        end
      end

      context "when user is not logged in" do
        let(:user) { nil }
        let(:export_candidacy) { create(:candidacy, :accepted, organization:) }

        context "when exporting pdf signatures" do
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_pdf_signatures, subject: :candidacy) }

          it { expect { subject }.to raise_error(Decidim::PermissionAction::PermissionNotSetError) }
        end

        context "when exporting xml signatures" do
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_xml_signatures, subject: :candidacy) }

          it { expect { subject }.to raise_error(Decidim::PermissionAction::PermissionNotSetError) }
        end

        context "when exporting votes" do
          let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :export_votes, subject: :candidacy) }

          it { expect { subject }.to raise_error(Decidim::PermissionAction::PermissionNotSetError) }
        end
      end
    end
  end
end
