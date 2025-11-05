# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    module Admin
      describe CandidacyAnswerForm do
        subject { described_class.from_model(candidacy).with_context(context) }

        let(:organization) { create(:organization) }
        let(:candidacies_type) { create(:candidacies_type, organization:) }
        let(:scope) { create(:candidacies_type_scope, type: candidacies_type) }

        let(:state) { "open" }

        let(:candidacy) { create(:candidacy, organization:, state:, scoped_type: scope) }
        let(:user) { create(:user, organization:) }

        let(:context) do
          {
            current_user: user,
            current_organization: organization,
            candidacy:
          }
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        describe "#signature_dates_required?" do
          subject { described_class.from_model(candidacy).with_context(context).signature_dates_required? }

          context "when created" do
            let(:state) { "created" }

            it { is_expected.to be(false) }
          end

          context "when open" do
            it { is_expected.to be(true) }
          end
        end
      end
    end
  end
end
