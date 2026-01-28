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

      context "when destroy" do
        let!(:vote) { create(:candidacy_user_vote, candidacy:, author: candidacy.author) }

        context "and authorized users" do
          it "Authorized users can unvote" do
            expect(vote).not_to be_nil

            expect do
              sign_in candidacy.author, scope: :user
              delete :destroy, params: { candidacy_slug: candidacy.slug, format: :js }
            end.to change { CandidaciesVote.where(candidacy:).count }.by(-1)
          end
        end

        context "and unvote disabled" do
          let(:candidacies_type) { create(:candidacies_type, :undo_online_signatures_disabled, organization:) }
          let(:scope) { create(:candidacies_type_scope, type: candidacies_type) }
          let(:candidacy) { create(:candidacy, organization:, scoped_type: scope) }

          it "does not remove the vote" do
            expect do
              sign_in candidacy.author, scope: :user
              delete :destroy, params: { candidacy_slug: candidacy.slug, format: :js }
            end.not_to(change { CandidaciesVote.where(candidacy:).count })
          end

          it "raises an exception" do
            sign_in candidacy.author, scope: :user
            delete :destroy, params: { candidacy_slug: candidacy.slug, format: :js }
            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end
      end
    end
  end
end
