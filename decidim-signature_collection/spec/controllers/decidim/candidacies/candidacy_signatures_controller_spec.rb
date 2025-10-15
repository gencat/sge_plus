# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    describe CandidacySignaturesController do
      routes { Decidim::Candidacies::Engine.routes }

      let(:organization) { create(:organization) }
      let(:candidacy_with_user_extra_fields) { create(:candidacy, :with_user_extra_fields_collection, organization:) }
      let(:candidacy_without_user_extra_fields) { create(:candidacy, organization:) }
      let(:candidacy) { candidacy_without_user_extra_fields }

      before do
        request.env["decidim.current_organization"] = organization
      end

      context "when POST create" do
        context "and authorized user" do
          context "and candidacy with user extra fields required" do
            it "cannot vote" do
              sign_in candidacy_with_user_extra_fields.author, scope: :user
              post :create, params: { candidacy_slug: candidacy_with_user_extra_fields.slug, format: :js }
              expect(response).to have_http_status(:unprocessable_entity)
              expect(response.content_type).to eq("text/javascript; charset=utf-8")
            end
          end

          context "and candidacy without user extra fields required" do
            it "can vote" do
              expect do
                sign_in candidacy_without_user_extra_fields.author, scope: :user
                post :create, params: { candidacy_slug: candidacy_without_user_extra_fields.slug, format: :js }
              end.to change { CandidacysVote.where(candidacy: candidacy_without_user_extra_fields).count }.by(1)
            end
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
            end.not_to(change { CandidacysVote.where(candidacy:).count })
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

      context "when GET candidacy_signatures" do
        context "and candidacy without user extra fields required" do
          it "action is unavailable" do
            sign_in candidacy_without_user_extra_fields.author, scope: :user
            expect(get(:fill_personal_data, params: { candidacy_slug: candidacy_without_user_extra_fields.slug })).to redirect_to("/")
          end
        end
      end
    end
  end
end
