# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # Controller used to manage the candidacies settings for the current
      # organization.
      class CandidacysSettingsController < Decidim::Candidacies::Admin::ApplicationController
        layout "decidim/admin/candidacies"

        add_breadcrumb_item_from_menu :admin_candidacies_menu

        # GET /admin/candidacies_settings/edit
        def edit
          enforce_permission_to :update, :candidacies_settings, candidacies_settings: current_candidacies_settings
          @form = candidacies_settings_form.from_model(current_candidacies_settings)
        end

        # PUT /admin/candidacies_settings
        def update
          enforce_permission_to :update, :candidacies_settings, candidacies_settings: current_candidacies_settings

          @form = candidacies_settings_form
                  .from_params(params, candidacies_settings: current_candidacies_settings)

          UpdateCandidacysSettings.call(@form, current_candidacies_settings) do
            on(:ok) do
              flash[:notice] = I18n.t("candidacies_settings.update.success", scope: "decidim.admin")
              redirect_to edit_candidacies_setting_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("candidacies_settings.update.error", scope: "decidim.admin")
              render :edit
            end
          end
        end

        private

        def current_candidacies_settings
          @current_candidacies_settings ||= Decidim::CandidacysSettings.find_or_create_by!(organization: current_organization)
        end

        def candidacies_settings_form
          form(Decidim::Candidacies::Admin::CandidacysSettingsForm)
        end
      end
    end
  end
end
