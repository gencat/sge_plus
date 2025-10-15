# frozen_string_literal: true

require "rails_helper"

module Decidim
  module Candidacies
    module Admin
      describe CandidacyTypeForm do
        subject { described_class.from_params(attributes).with_context(context) }

        let(:organization) { create(:organization) }
        let(:candidacies_type) { create(:candidacies_type, organization:) }
        let(:title) { Decidim::Faker::Localized.sentence(word_count: 5) }
        let(:promoting_committee_enabled) { true }
        let(:minimum_committee_members) { 5 }
        let(:comments_enabled) { true }
        let(:attributes) do
          {
            title:,
            description: Decidim::Faker::Localized.sentence(word_count: 25),
            online_signature_enabled: false,
            attachments_enabled: true,
            custom_signature_end_date_enabled: true,
            undo_online_signatures_enabled: false,
            area_enabled: false,
            comments_enabled:,
            promoting_committee_enabled:,
            minimum_committee_members:,
            banner_image: Decidim::Dev.test_file("city2.jpeg", "image/jpeg")
          }
        end
        let(:context) do
          {
            current_organization: candidacies_type.organization,
            current_component: nil
          }
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "when minimum_committee_members is blank" do
          let(:minimum_committee_members) { " " }

          it "is 2" do
            expect(subject.minimum_committee_members).to eq(2)
          end
        end

        context "when title is missing" do
          let(:title) { nil }

          it { is_expected.to be_invalid }
        end

        context "when the promoting committee is not enabled" do
          let(:promoting_committee_enabled) { false }

          it "sets 0 as minimum committee members" do
            expect(subject.minimum_committee_members).to eq(2)
          end
        end

        context "when comments are disabled" do
          let(:comments_enabled) { false }

          it { is_expected.to be_valid }
        end

        context "when validating signature period" do
          context "when start is after end" do
            let(:attributes) do
              super().merge(signature_period_start: 2.days.from_now, signature_period_end: 1.day.from_now)
            end

            it { is_expected.to be_invalid }
          end

          context "when start is before end" do
            let(:attributes) do
              super().merge(signature_period_start: 1.day.from_now, signature_period_end: 2.days.from_now)
            end

            it { is_expected.to be_valid }
          end
        end
      end
    end
  end
end
