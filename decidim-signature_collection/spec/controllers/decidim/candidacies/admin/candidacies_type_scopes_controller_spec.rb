# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    module Admin
      describe CandidacysTypeScopesController do
        routes { Decidim::Candidacies::AdminEngine.routes }

        let(:organization) { create(:organization) }
        let(:admin_user) { create(:user, :confirmed, :admin, organization:) }
        let(:user) { create(:user, :confirmed, :admin_terms_accepted, organization:) }
        let(:candidacy_type) do
          create(:candidacies_type, organization:)
        end
        let(:candidacy_type_scope) do
          create(:candidacies_type_scope, type: candidacy_type)
        end

        let(:valid_attributes) do
          attrs = attributes_for(:candidacies_type_scope, type: candidacy_type)
          {
            decidim_scopes_id: attrs[:scope],
            supports_required: attrs[:supports_required]
          }
        end

        let(:invalid_attributes) do
          attrs = attributes_for(:candidacies_type_scope, type: candidacy_type)
          {
            decidim_scopes_id: attrs[:scope],
            supports_required: nil
          }
        end

        before do
          request.env["decidim.current_organization"] = organization
        end

        context "when new" do
          context "and admin user" do
            before do
              sign_in admin_user, scope: :user
            end

            it "gets loaded" do
              get :new, params: { candidacies_type_id: candidacy_type.id }
              expect(flash[:alert]).to be_nil
              expect(response).to have_http_status(:ok)
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              get :new, params: { candidacies_type_id: candidacy_type.id }
              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:found)
            end
          end
        end

        context "when create" do
          context "and admin user" do
            before do
              sign_in admin_user, scope: :user
            end

            it "gets created" do
              expect do
                post :create,
                     params: {
                       candidacies_type_id: candidacy_type.id,
                       candidacies_type_scope: valid_attributes
                     }
              end.to change(CandidacysTypeScope, :count).by(1)
            end

            it "fails creation" do
              expect do
                post :create,
                     params: {
                       candidacies_type_id: candidacy_type.id,
                       candidacies_type_scope: invalid_attributes
                     }
              end.not_to change(CandidacysTypeScope, :count)
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              post :create,
                   params: {
                     candidacies_type_id: candidacy_type.id,
                     candidacies_type_scope: valid_attributes
                   }
              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:found)
            end
          end
        end

        context "when edit" do
          context "and admin user" do
            before do
              sign_in admin_user, scope: :user
            end

            it "gets loaded" do
              get :edit,
                  params: {
                    candidacies_type_id: candidacy_type.id,
                    id: candidacy_type_scope.to_param
                  }
              expect(flash[:alert]).to be_nil
              expect(response).to have_http_status(:ok)
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              get :edit,
                  params: {
                    candidacies_type_id: candidacy_type.id,
                    id: candidacy_type_scope.to_param
                  }
              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:found)
            end
          end
        end

        context "when update" do
          context "and admin user" do
            before do
              sign_in admin_user, scope: :user
            end

            it "gets updated" do
              patch :update,
                    params: {
                      candidacies_type_id: candidacy_type.to_param,
                      id: candidacy_type_scope.to_param,
                      candidacies_type_scope: valid_attributes
                    }
              expect(flash[:alert]).to be_nil

              candidacy_type_scope.reload
              expect(candidacy_type_scope.supports_required).to eq(valid_attributes[:supports_required])
            end

            it "fails update" do
              patch :update,
                    params: {
                      candidacies_type_id: candidacy_type.to_param,
                      id: candidacy_type_scope.to_param,
                      candidacies_type_scope: invalid_attributes
                    }
              expect(flash[:alert]).not_to be_empty
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              patch :update,
                    params: {
                      candidacies_type_id: candidacy_type.to_param,
                      id: candidacy_type_scope.to_param,
                      candidacies_type_scope: valid_attributes
                    }
              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:found)
            end
          end
        end

        context "when destroy" do
          context "and admin user" do
            before do
              sign_in admin_user
            end

            it "removes the candidacy type if not used" do
              delete :destroy,
                     params: {
                       candidacies_type_id: candidacy_type.id,
                       id: candidacy_type_scope.to_param
                     }

              scope = CandidacysTypeScope.find_by(id: candidacy_type_scope.id)
              expect(scope).to be_nil
            end

            it "fails if the candidacy type scope is being used" do
              create(:candidacy, organization:, scoped_type: candidacy_type_scope)

              expect do
                delete :destroy,
                       params: {
                         candidacies_type_id: candidacy_type.id,
                         id: candidacy_type_scope.to_param
                       }
              end.not_to change(CandidacysTypeScope, :count)
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              delete :destroy,
                     params: {
                       candidacies_type_id: candidacy_type.id,
                       id: candidacy_type_scope.to_param
                     }
              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:found)
            end
          end
        end
      end
    end
  end
end
