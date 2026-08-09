# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

module Decidim
  module SignatureCollection
    describe CandidacyApiType, type: :graphql do
      include_context "with a graphql class type"

      let(:model) { create(:candidacies_type) }

      describe "id" do
        let(:query) { "{ id }" }

        it "returns the id field" do
          expect(response).to include("id" => model.id.to_s)
        end
      end

      describe "title" do
        let(:query) { '{ title { translation(locale: "en")}}' }

        it "returns the title field" do
          expect(response["title"]["translation"]).to eq(model.title["en"])
        end
      end

      describe "createdAt" do
        let(:query) { "{ createdAt }" }

        it "returns when the candidacy type was created" do
          expect(response["createdAt"]).to eq(model.created_at.to_time.iso8601)
        end
      end

      describe "updatedAt" do
        let(:query) { "{ updatedAt }" }

        it "returns when the candidacy type was updated" do
          expect(response["updatedAt"]).to eq(model.updated_at.to_time.iso8601)
        end
      end

      describe "description" do
        let(:query) { '{ description { translation(locale: "en")}}' }

        it "returns all the required fields" do
          expect(response["description"]["translation"]).to eq(model.description["en"])
        end
      end

      describe "extraFieldsLegalInformation" do
        let(:query) { "{ extraFieldsLegalInformation }" }

        it "returns the extra fields legal information field" do
          expect(response["extraFieldsLegalInformation"]).to eq(model.extra_fields_legal_information)
        end
      end

      describe "minimumCommitteeMembers" do
        let(:query) { "{ minimumCommitteeMembers }" }

        it "returns the minimum committee members field" do
          expect(response["minimumCommitteeMembers"]).to eq(model.minimum_committee_members)
        end
      end

      describe "undoOnlineSignaturesEnabled" do
        let(:query) { "{ undoOnlineSignaturesEnabled }" }

        it "returns the undo online signatures enabled field" do
          expect(response["undoOnlineSignaturesEnabled"]).to eq(model.undo_online_signatures_enabled)
        end
      end

      describe "promotingCommitteeEnabled" do
        let(:query) { "{ promotingCommitteeEnabled }" }

        it "returns the promoting committee enabled field" do
          expect(response["promotingCommitteeEnabled"]).to eq(model.promoting_committee_enabled)
        end
      end

      describe "signatureType" do
        let(:query) { "{ signatureType }" }

        it "returns the signature type field" do
          expect(response["signatureType"]).to eq(model.signature_type)
        end
      end

      describe "candidacies" do
        let(:query) { "{ candidacies { id } }" }

        context "when there are no candidacies" do
          it "returns the candidacies for this type" do
            expect(response["candidacies"]).to eq(model.candidacies)
          end
        end

        context "when there are candidacies" do
          let(:scoped_type) { create(:candidacies_type_scope, type: model) }
          let!(:candidacies) { create_list(:candidacy, 5, scoped_type:, organization: model.organization) }

          it "returns the candidacies" do
            ids = response["candidacies"].map { |item| item["id"] }
            expect(ids).to include(*model.candidacies.map(&:id).map(&:to_s))
          end
        end
      end
    end
  end
end
