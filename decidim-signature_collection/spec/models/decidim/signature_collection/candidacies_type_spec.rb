# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidaciesType do
      let(:candidacies_type) { build(:candidacies_type) }

      it "is valid" do
        expect(candidacies_type).to be_valid
      end

      describe "::candidacies" do
        let(:organization) { create(:organization) }
        let(:candidacies_type) { create(:candidacies_type, organization:) }
        let(:scope) { create(:candidacies_type_scope, type: candidacies_type) }
        let!(:candidacy) { create(:candidacy, organization:, scoped_type: scope) }
        let!(:other_candidacy) { create(:candidacy) }

        it "returns candidacies" do
          expect(candidacies_type.candidacies).to include(candidacy)
          expect(candidacies_type.candidacies).not_to include(other_candidacy)
        end
      end
    end
  end
end
