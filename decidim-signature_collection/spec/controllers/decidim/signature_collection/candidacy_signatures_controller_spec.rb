# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidacySignaturesController, skip: "Awaiting review" do
      routes { Decidim::SignatureCollection::Engine.routes }

      let(:organization) { create(:organization) }
      let(:candidacy) { create(:candidacy, organization:) }
      let(:params) do
        {
          candidacy_slug: candidacy.slug,
          document_number: "12345678Z",
          document_type: 1,
          name: "John",
          first_surname: "Doe",
          date_of_birth: "1990-01-01",
          postal_code: "08001",
          format: :js
        }
      end

      before do
        request.env["decidim.current_organization"] = organization
      end

      context "when POST create" do
        context "with a logged user" do
          it "can vote" do
            sign_in candidacy.author, scope: :user

            expect do
              sign_in candidacy.author, scope: :user
              post :create, params: params
            end.to change { CandidaciesVote.where(candidacy: candidacy).count }.by(1)
          end
        end

        context "and Guest users" do
          it "receives unauthorized response" do
            post :create, params: { candidacy_slug: candidacy.slug, format: :js }
            expect(response).to have_http_status(:unauthorized)
          end

          it "do not register the vote" do
            expect do
              post :create, params: { candidacy_slug: candidacy.slug, format: :js }
            end.not_to(change { CandidaciesVote.where(candidacy:).count })
          end
        end
      end

      context "when GET show first step" do
        let(:candidacy) { candidacy_with_user_extra_fields }

        context "and Authorized user" do
          it "can get first step" do
            sign_in candidacy.author, scope: :user

            get :fill_personal_data, params: { candidacy_slug: candidacy.slug }
            expect(subject.helpers.current_candidacy).to eq(candidacy)
            expect(subject.helpers.extra_data_legal_information).to eq(candidacy.scoped_type.type.extra_fields_legal_information)
          end
        end
      end
    end
  end
end
