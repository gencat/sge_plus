# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    module Admin
      describe CandidacysSettingsForm do
        subject { described_class.from_params(attributes).with_context(current_organization: organization) }

        let(:organization) { create(:organization) }
        let(:candidacies_order) { "date" }

        let(:attributes) do
          {
            "candidacies_order" => candidacies_order
          }
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end
      end
    end
  end
end
