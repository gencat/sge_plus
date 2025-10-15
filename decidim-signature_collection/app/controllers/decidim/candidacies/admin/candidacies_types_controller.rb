# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # Controller used to manage the available candidacy types for the current
      # organization.
      class CandidacysTypesController < Decidim::Candidacies::Admin::ApplicationController
        include Decidim::TranslatableAttributes
        before_action :set_controller_breadcrumb, except: [:index, :new, :create]

        add_breadcrumb_item_from_menu :admin_candidacies_menu

        helper ::Decidim::Admin::ResourcePermissionsHelper
        helper_method :current_candidacy_type

        # GET /admin/candidacies_types
        def index
          enforce_permission_to :index, :candidacy_type

          @candidacies_types = CandidacyTypes.for(current_organization)
        end

        # GET /admin/candidacies_types/new
        def new
          enforce_permission_to :create, :candidacy_type
          @form = candidacy_type_form.instance
        end

        # POST /admin/candidacies_types
        def create
          enforce_permission_to :create, :candidacy_type
          @form = candidacy_type_form.from_params(params)

          CreateCandidacyType.call(@form) do
            on(:ok) do |candidacy_type|
              flash[:notice] = I18n.t("decidim.candidacies.admin.candidacies_types.create.success")
              redirect_to edit_candidacies_type_path(candidacy_type)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("decidim.candidacies.admin.candidacies_types.create.error")
              render :new
            end
          end
        end

        # GET /admin/candidacies_types/:id/edit
        def edit
          enforce_permission_to :edit, :candidacy_type, candidacy_type: current_candidacy_type
          @form = candidacy_type_form
                  .from_model(current_candidacy_type,
                              candidacy_type: current_candidacy_type)
        end

        # PUT /admin/candidacies_types/:id
        def update
          enforce_permission_to :update, :candidacy_type, candidacy_type: current_candidacy_type

          @form = candidacy_type_form
                  .from_params(params, candidacy_type: current_candidacy_type)

          UpdateCandidacyType.call(@form, current_candidacy_type) do
            on(:ok) do
              flash[:notice] = I18n.t("decidim.candidacies.admin.candidacies_types.update.success")
              redirect_to edit_candidacies_type_path(current_candidacy_type)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("decidim.candidacies.admin.candidacies_types.update.error")
              render :edit
            end
          end
        end

        # DELETE /admin/candidacies_types/:id
        def destroy
          enforce_permission_to :destroy, :candidacy_type, candidacy_type: current_candidacy_type

          Decidim.traceability.perform_action!("delete", current_candidacy_type, current_user) do
            current_candidacy_type.destroy!
          end

          redirect_to candidacies_types_path, flash: {
            notice: I18n.t("decidim.candidacies.admin.candidacies_types.destroy.success")
          }
        end

        private

        def set_controller_breadcrumb
          controller_breadcrumb_items <<
            {
              label: translated_attribute(current_candidacy_type.title),
              url: edit_candidacies_type_path(current_candidacy_type),
              active: true
            }
        end

        def current_candidacy_type
          @current_candidacy_type ||= CandidacysType.where(organization: current_organization).find(params[:id])
        end

        def candidacy_type_form
          form(Decidim::Candidacies::Admin::CandidacyTypeForm)
        end
      end
    end
  end
end
