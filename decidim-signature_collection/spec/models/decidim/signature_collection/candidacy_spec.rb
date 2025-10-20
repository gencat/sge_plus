# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe SignatureCollection::Candidacy do
    subject { candidacy }

    let(:organization) { create(:organization) }
    let(:candidacy) { build(:candidacy) }

    let(:candidacies_type_minimum_committee_members) { 2 }
    let(:candidacies_type) do
      create(
        :candidacies_type,
        organization:,
        minimum_committee_members: candidacies_type_minimum_committee_members
      )
    end
    let(:scoped_type) { create(:candidacies_type_scope, type: candidacies_type) }

    include_examples "has reference"

    context "when created candidacy" do
      let(:candidacy) { create(:candidacy, :created) }
      let(:administrator) { create(:user, :admin, organization: candidacy.organization) }
      let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
      let(:offline_type) { create(:candidacies_type, :online_signature_disabled, organization:) }
      let(:offline_scope) { create(:candidacies_type_scope, type: offline_type) }

      before do
        allow(message_delivery).to receive(:deliver_later)
      end

      it "is versioned" do
        expect(candidacy).to be_versioned
      end

      it "enforces signature types specified in the type" do
        online_candidacy = build(:candidacy, :created, organization:, scoped_type: offline_scope, signature_type: "online")
        offline_candidacy = build(:candidacy, :created, organization:, scoped_type: offline_scope, signature_type: "offline")

        expect(online_candidacy).to be_invalid
        expect(offline_candidacy).to be_valid
      end

      it "Creation is notified by email" do
        expect(Decidim::SignatureCollection::CandidaciesMailer).to receive(:notify_creation)
          .at_least(:once)
          .at_most(:once)
          .and_return(message_delivery)
        candidacy = build(:candidacy, :created)
        candidacy.save!
      end
    end

    context "when published candidacy" do
      let(:published_candidacy) { build(:candidacy) }
      let(:online_allowed_type) { create(:candidacies_type, :online_signature_enabled, organization:) }
      let(:online_allowed_scope) { create(:candidacies_type_scope, type: online_allowed_type) }

      it "is valid" do
        expect(published_candidacy).to be_valid
      end

      it "does not enforce signature type if the type was updated" do
        candidacy = build(:candidacy, organization:, scoped_type: online_allowed_scope, signature_type: "online")

        expect(candidacy.save).to be_truthy

        online_allowed_type.update!(signature_type: "offline")

        expect(candidacy).to be_valid
      end

      it "unpublish!" do
        published_candidacy.unpublish!

        expect(published_candidacy).to be_discarded
        expect(published_candidacy.published_at).to be_nil
      end

      it "signature_interval_defined?" do
        expect(published_candidacy).to have_signature_interval_defined
      end

      context "when mailing" do
        let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

        before do
          allow(message_delivery).to receive(:deliver_later)
        end

        it "Acceptation is notified by email" do
          expect(Decidim::SignatureCollection::CandidaciesMailer).to receive(:notify_state_change)
            .at_least(:once)
            .and_return(message_delivery)
          published_candidacy.accepted!
        end

        it "Rejection is notified by email" do
          expect(Decidim::SignatureCollection::CandidaciesMailer).to receive(:notify_state_change)
            .at_least(:once)
            .and_return(message_delivery)
          published_candidacy.rejected!
        end
      end
    end

    context "when validating candidacy" do
      let(:validating_candidacy) do
        build(:candidacy,
              state: "validating",
              published_at: nil,
              signature_start_date: nil,
              signature_end_date: nil)
      end

      it "is valid" do
        expect(validating_candidacy).to be_valid
      end

      it "publish!" do
        validating_candidacy.publish!
        expect(validating_candidacy).to have_signature_interval_defined
        expect(validating_candidacy.published_at).not_to be_nil
      end

      context "when mailing" do
        let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

        before do
          allow(message_delivery).to receive(:deliver_later)
        end

        it "publication is notified by email" do
          expect(Decidim::SignatureCollection::CandidaciesMailer).to receive(:notify_state_change)
            .at_least(:once)
            .and_return(message_delivery)
          validating_candidacy.publish!
        end

        it "Discard is notified by email" do
          expect(Decidim::SignatureCollection::CandidaciesMailer).to receive(:notify_state_change)
            .at_least(:once)
            .and_return(message_delivery)
          validating_candidacy.discarded!
        end
      end
    end

    context "when has_authorship?" do
      let(:candidacy) { create(:candidacy) }
      let(:user) { create(:user) }
      let(:pending_committee_member) { create(:candidacies_committee_member, :requested, candidacy:) }
      let(:rejected_committee_member) { create(:candidacies_committee_member, :rejected, candidacy:) }

      it "returns true for the candidacy author" do
        expect(candidacy).to have_authorship(candidacy.author)
      end

      it "returns true for approved promotal committee members" do
        expect(candidacy).not_to have_authorship(pending_committee_member.user)
        expect(candidacy).not_to have_authorship(rejected_committee_member.user)

        expect(candidacy.committee_members.approved).to be_any

        candidacy.committee_members.approved.each do |m|
          expect(candidacy).to have_authorship(m.user)
        end
      end

      it "returns false for any other user" do
        expect(candidacy).not_to have_authorship(user)
      end
    end

    describe "signatures calculations" do
      let!(:candidacy) { create(:candidacy, signature_type:) }
      let(:scope_id) { candidacy.scope.id.to_s }
      let!(:other_scope_for_type) { create(:candidacies_type_scope, type: candidacy.type) }

      context "with only online candidacies" do
        let(:signature_type) { "online" }

        it "ignores any value in offline_votes attribute" do
          candidacy.update(offline_votes: { scope_id => candidacy.scoped_type.supports_required, "total" => candidacy.scoped_type.supports_required },
                           online_votes: { scope_id => candidacy.scoped_type.supports_required / 2, "total" => candidacy.scoped_type.supports_required / 2 })
          expect(candidacy.percentage).to eq(50)
          expect(candidacy).not_to be_supports_goal_reached
        end

        it "cannot be greater than 100" do
          candidacy.update(online_votes: { scope_id => candidacy.scoped_type.supports_required, "total" => candidacy.scoped_type.supports_required * 2 })
          expect(candidacy.percentage).to eq(100)
          expect(candidacy).to be_supports_goal_reached
        end
      end

      context "with face-to-face support too" do
        let(:signature_type) { "any" }

        it "returns the percentage of votes reached" do
          online_votes = candidacy.scoped_type.supports_required / 4
          offline_votes = candidacy.scoped_type.supports_required / 4
          candidacy.update(offline_votes: { scope_id => offline_votes, "total" => offline_votes },
                           online_votes: { scope_id => online_votes, "total" => online_votes })
          expect(candidacy.percentage).to eq(50)
          expect(candidacy).not_to be_supports_goal_reached
        end

        it "cannot be greater than 100" do
          online_votes = candidacy.scoped_type.supports_required * 4
          offline_votes = candidacy.scoped_type.supports_required * 4
          candidacy.update(offline_votes: { scope_id => offline_votes, "total" => offline_votes },
                           online_votes: { scope_id => online_votes, "total" => online_votes })
          expect(candidacy.percentage).to eq(100)
          expect(candidacy).to be_supports_goal_reached
        end
      end
    end

    describe "#minimum_committee_members" do
      subject { candidacy.minimum_committee_members }

      let(:committee_members_fallback_setting) { 1 }
      let(:candidacy) { create(:candidacy, organization:, scoped_type:) }

      before do
        allow(Decidim::SignatureCollection).to(
          receive(:minimum_committee_members).and_return(committee_members_fallback_setting)
        )
      end

      context "when setting defined in type" do
        it { is_expected.to eq candidacies_type_minimum_committee_members }
      end

      context "when setting not set" do
        let(:candidacies_type_minimum_committee_members) { nil }

        it { is_expected.to eq committee_members_fallback_setting }
      end
    end

    describe "#enough_committee_members?" do
      subject { candidacy.enough_committee_members? }

      let(:candidacies_type_minimum_committee_members) { 2 }
      let(:candidacy) { create(:candidacy, organization:, scoped_type:) }

      before { candidacy.committee_members.destroy_all }

      context "when enough members" do
        before { create_list(:candidacies_committee_member, candidacies_type_minimum_committee_members, candidacy:) }

        it { is_expected.to be true }
      end

      context "when not enough members" do
        before { create_list(:candidacies_committee_member, candidacies_type_minimum_committee_members - 1, candidacy:) }

        it { is_expected.to be false }
      end
    end

    describe "#missing_committee_members" do
      subject { candidacy.missing_committee_members }

      let(:candidacies_type_minimum_committee_members) { 2 }
      let(:candidacy) { create(:candidacy, organization:, scoped_type:) }

      before { candidacy.committee_members.destroy_all }

      context "when all missing members" do
        it { is_expected.to be 2 }
      end

      context "when one missing member" do
        before { create(:candidacies_committee_member, candidacy:) }

        it { is_expected.to be 1 }
      end

      context "when no missing members" do
        before { create_list(:candidacies_committee_member, candidacies_type_minimum_committee_members, candidacy:) }

        it { is_expected.to be 0 }
      end
    end

    describe "sorting" do
      subject(:sorter) { described_class.ransack("s" => "supports_count desc") }

      before do
        create(:candidacy, organization:, signature_type: "offline")
        create(:candidacy, organization:, signature_type: "offline", offline_votes: { "total" => 4 })
        create(:candidacy, organization:, signature_type: "online", online_votes: { "total" => 5 })
        create(:candidacy, organization:, signature_type: "online", online_votes: { "total" => 3 })
        create(:candidacy, organization:, signature_type: "any", online_votes: { "total" => 1 })
        create(:candidacy, organization:, signature_type: "any", online_votes: { "total" => 5 }, offline_votes: { "total" => 3 })
      end

      it "sorts candidacies by supports count" do
        expect(sorter.result.map(&:supports_count)).to eq([8, 5, 4, 3, 1, 0])
      end
    end

    describe "signature period logic" do
      let(:type) { candidacies_type }
      let(:scope) { scoped_type }
      let(:attrs) do
        {
          organization: organization,
          scoped_type: scope,
          title: { en: "I" },
          description: { en: "Desc" },
          signature_type: "online"
        }
      end

      it "recognizes full_period and is active when now is inside the interval" do
        type.update!(signature_period_start: 1.hour.ago, signature_period_end: 1.hour.from_now)
        candidacy = create(:candidacy, **attrs, published_at: Time.current)
        expect(candidacy.signature_period_type).to eq(:full_period)
        expect(candidacy.signature_period_active?).to be true
        expect(candidacy.votes_enabled?).to be true
      end

      it "recognizes from_start_to_indefinite when only start is set" do
        type.update!(signature_period_start: 1.hour.ago, signature_period_end: nil)
        candidacy = create(:candidacy, **attrs, published_at: Time.current)

        expect(candidacy.signature_period_type).to eq(:from_start_to_indefinite)
        expect(candidacy.signature_period_active?).to be true
      end

      it "recognizes from_publication_to_end when only end is set" do
        type.update!(signature_period_start: nil, signature_period_end: 1.day.from_now)
        candidacy = create(:candidacy, **attrs, published_at: Time.current)

        expect(candidacy.signature_period_type).to eq(:from_publication_to_end)
        expect(candidacy.signature_period_active?).to be true
      end

      it "recognizes no_period when neither date is set" do
        type.update!(signature_period_start: nil, signature_period_end: nil)
        candidacy = create(:candidacy, **attrs, published_at: Time.current)

        expect(candidacy.signature_period_type).to eq(:no_period)
        expect(candidacy.signature_period_active?).to be false
        expect(candidacy.votes_enabled?).to be false
      end

      it "signature_period_description includes hours when both dates present" do
        start_dt = Time.current.change(hour: 9, min: 30)
        end_dt = 2.days.from_now.change(hour: 18, min: 15)
        type.update!(signature_period_start: start_dt, signature_period_end: end_dt)

        candidacy = create(:candidacy, **attrs, published_at: Time.current)
        desc = candidacy.signature_period_description

        expect(desc).to include("09:30")
        expect(desc).to include("18:15")
      end
    end
  end
end
