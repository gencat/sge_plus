# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidaciesType, skip: "Awaiting review" do

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

      describe "#minimum_signing_age?" do
        context "when minimum_signing_age is present" do
          let(:candidacies_type) { build(:candidacies_type, minimum_signing_age: 16) }

          it "returns true" do
            expect(candidacies_type.minimum_signing_age?).to be true
          end
        end

        context "when minimum_signing_age is nil" do
          let(:candidacies_type) { build(:candidacies_type, minimum_signing_age: nil) }

          it "returns false" do
            expect(candidacies_type.minimum_signing_age?).to be false
          end
        end

        context "when minimum_signing_age is zero" do
          let(:candidacies_type) { build(:candidacies_type, minimum_signing_age: 0) }

          it "returns false" do
            expect(candidacies_type.minimum_signing_age?).to be false
          end
        end
      end
    end
  end
end
