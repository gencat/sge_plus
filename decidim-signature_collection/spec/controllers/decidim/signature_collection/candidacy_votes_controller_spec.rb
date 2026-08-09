# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidacyVotesController, skip: "Awaiting review" do
      routes { Decidim::SignatureCollection::Engine.routes }

      let(:organization) { create(:organization) }
      let(:candidacy) { create(:candidacy, organization:) }

      before do
        request.env["decidim.current_organization"] = organization
      end

      context "when POST create" do
        context "and Authorized users" do
          it "Authorized users can vote" do
            expect do
              sign_in candidacy.author, scope: :user
              post :create, params: { candidacy_slug: candidacy.slug, format: :js }
            end.to change { CandidaciesVote.where(candidacy:).count }.by(1)
          end
        end

        context "and guest users" do
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
    end
  end
end
