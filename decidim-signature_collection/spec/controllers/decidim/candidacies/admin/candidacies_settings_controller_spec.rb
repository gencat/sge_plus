# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    module Admin
      describe CandidacysSettingsController do
        routes { Decidim::Candidacies::AdminEngine.routes }

        let(:organization) { create(:organization) }
        let(:current_user) { create(:user, :confirmed, :admin, organization:) }
        let!(:candidacies_settings) { create(:candidacies_settings, organization:) }

        before do
          request.env["decidim.current_organization"] = organization
          sign_in current_user
        end

        describe "PATCH update" do
          let(:candidacies_settings_params) do
            {
              candidacies_order: candidacies_settings.candidacies_order
            }
          end

          it "updates the candidacies settings" do
            patch :update, params: { id: candidacies_settings.id, candidacies_settings: candidacies_settings_params }

            expect(response).to redirect_to edit_candidacies_setting_path
          end
        end
      end
    end
  end
end
