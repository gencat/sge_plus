# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    module Admin
      describe CandidaciesTypesController do
        routes { Decidim::SignatureCollection::AdminEngine.routes }

        let(:organization) { create(:organization) }
        let(:admin_user) { create(:user, :confirmed, :admin, organization:) }
        let(:user) { create(:user, :confirmed, :admin_terms_accepted, organization:) }
        let(:candidacy_type) do
          create(:candidacies_type, organization:)
        end

        let(:valid_attributes) do
          attributes_for(:candidacies_type, organization:)
        end

        let(:invalid_attributes) do
          attributes_for(:candidacies_type, organization:, title: { "en" => "" })
        end

        before do
          request.env["decidim.current_organization"] = organization
        end

        context "when index" do
          context "and admin user" do
            before do
              sign_in admin_user, scope: :user
            end

            it "gets loaded" do
              get :index
              expect(flash[:alert]).to be_nil
              expect(response).to have_http_status(:ok)
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              get :index
              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:found)
            end
          end
        end

        context "when new" do
          context "and admin user" do
            before do
              sign_in admin_user, scope: :user
            end

            it "gets loaded" do
              get :new
              expect(flash[:alert]).to be_nil
              expect(response).to have_http_status(:ok)
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              get :new
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
                post :create, params: { candidacies_type: valid_attributes }
              end.to change(CandidaciesType, :count).by(1)
            end

            it "fails creation" do
              expect do
                post :create, params: { candidacies_type: invalid_attributes }
              end.not_to change(CandidaciesType, :count)
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              post :create,
                   params: { candidacies_type: valid_attributes }
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
              get :edit, params: { id: candidacy_type.to_param }
              expect(flash[:alert]).to be_nil
              expect(response).to have_http_status(:ok)
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              get :edit, params: { id: candidacy_type.to_param }
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
                      id: candidacy_type.id,
                      candidacies_type: valid_attributes
                    }
              expect(flash[:alert]).to be_nil

              candidacy_type.reload
              expect(candidacy_type.title.except("machine_translations")).to eq(valid_attributes[:title].except("machine_translations"))
              expect(candidacy_type.description.except("machine_translations")).to eq(valid_attributes[:description].except("machine_translations"))
            end

            it "fails update" do
              patch :update,
                    params: {
                      id: candidacy_type.id,
                      candidacies_type: invalid_attributes
                    }
              expect(flash[:alert]).not_to be_empty
            end
          end

          context "when regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              patch :update,
                    params: {
                      id: candidacy_type.id,
                      candidacies_type: valid_attributes
                    }
              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:found)
            end
          end
        end

        context "when destroy" do
          context "and admin user" do
            before do
              sign_in admin_user, scope: :user
            end

            it "removes the candidacy type if not used" do
              delete :destroy, params: { id: candidacy_type.id }
              expect(CandidaciesType.find_by(id: candidacy_type.id)).to be_nil
            end

            it "fails if the candidacy type is being used" do
              scoped_type = create(:candidacies_type_scope, type: candidacy_type)
              create(:candidacy, organization:, scoped_type:)

              expect do
                delete :destroy, params: { id: candidacy_type.id }
              end.not_to change(CandidaciesType, :count)
            end

            it "traces the action", versioning: true do
              expect(Decidim.traceability)
                .to receive(:perform_action!)
                .with("delete", candidacy_type, admin_user)
                .and_call_original

              expect { delete :destroy, params: { id: candidacy_type.id } }.to change(Decidim::ActionLog, :count)
              action_log = Decidim::ActionLog.last
              expect(action_log.action).to eq("delete")
              expect(action_log.version).to be_present
            end
          end

          context "and regular user" do
            before do
              sign_in user, scope: :user
            end

            it "access denied" do
              delete :destroy, params: { id: candidacy_type.id }
              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:found)
            end
          end
        end
      end
    end
  end
end
