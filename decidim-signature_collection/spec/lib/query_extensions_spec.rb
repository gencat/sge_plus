# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

module Decidim
  module Candidacies
    describe Decidim::Api::QueryType do
      include_context "with a graphql class type"

      describe "candidaciesTypes" do
        let!(:candidacies_type1) { create(:candidacies_type, organization: current_organization) }
        let!(:candidacies_type2) { create(:candidacies_type, organization: current_organization) }
        let!(:candidacies_type3) { create(:candidacies_type) }

        let(:query) { %({ candidaciesTypes { id }}) }

        it "returns all the groups" do
          expect(response["candidaciesTypes"]).to include("id" => candidacies_type1.id.to_s)
          expect(response["candidaciesTypes"]).to include("id" => candidacies_type2.id.to_s)
          expect(response["candidaciesTypes"]).not_to include("id" => candidacies_type3.id.to_s)
        end
      end

      describe "candidaciesType" do
        let(:model) { create(:candidacies_type, organization: current_organization) }
        let(:query) { %({ candidaciesType(id: "#{model.id}") { id }}) }

        it "returns the candidaciesType" do
          expect(response["candidaciesType"]).to eq("id" => model.id.to_s)
        end
      end

      describe "candidacies" do
        let!(:candidacy1) { create(:candidacy, organization: current_organization) }
        let!(:candidacy2) { create(:candidacy, organization: current_organization) }
        let!(:candidacy3) { create(:candidacy) }

        let(:query) { %({ candidacies { id }}) }

        it "returns all the candidacies" do
          expect(response["candidacies"]).to include("id" => candidacy1.id.to_s)
          expect(response["candidacies"]).to include("id" => candidacy2.id.to_s)
          expect(response["candidacies"]).not_to include("id" => candidacy3.id.to_s)
        end
      end

      describe "candidacy" do
        let(:query) { %({ candidacy(id: "#{id}") { id }}) }

        context "with an candidacy that belongs to the current organization" do
          let!(:candidacy) { create(:candidacy, organization: current_organization) }
          let(:id) { candidacy.id }

          it "returns the candidacy" do
            expect(response["candidacy"]).to eq("id" => candidacy.id.to_s)
          end
        end

        context "with a conference of another organization" do
          let!(:candidacy) { create(:candidacy) }
          let(:id) { candidacy.id }

          it "returns nil" do
            expect(response["candidacy"]).to be_nil
          end
        end
      end
    end
  end
end
