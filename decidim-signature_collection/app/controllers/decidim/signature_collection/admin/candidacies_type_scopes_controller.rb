# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # Controller used to manage the available candidacy type scopes
      class CandidaciesTypeScopesController < Decidim::SignatureCollection::Admin::ApplicationController
        include Decidim::TranslatableAttributes

        before_action :set_controller_breadcrumb
        add_breadcrumb_item_from_menu :admin_candidacies_menu

        helper_method :current_candidacy_type_scope

        # GET /admin/candidacies_types/:candidacies_type_id/candidacies_type_scopes/new
        def new
          enforce_permission_to :create, :candidacy_type_scope
          @form = candidacy_type_scope_form.instance
        end

        # POST /admin/candidacies_types/:candidacies_type_id/candidacies_type_scopes
        def create
          enforce_permission_to :create, :candidacy_type_scope
          @form = candidacy_type_scope_form
                  .from_params(params, type_id: params[:candidacies_type_id])

          CreateCandidacyTypeScope.call(@form) do
            on(:ok) do |candidacy_type_scope|
              flash[:notice] = I18n.t("decidim.signature_collection.admin.candidacies_type_scopes.create.success")
              redirect_to edit_candidacies_type_path(candidacy_type_scope.type)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("decidim.signature_collection.admin.candidacies_type_scopes.create.error")
              render :new
            end
          end
        end

        # GET /admin/candidacies_types/:candidacies_type_id/candidacies_type_scopes/:id/edit
        def edit
          enforce_permission_to :edit, :candidacy_type_scope, candidacy_type_scope: current_candidacy_type_scope
          @form = candidacy_type_scope_form.from_model(current_candidacy_type_scope)
        end

        # PUT /admin/candidacies_types/:candidacies_type_id/candidacies_type_scopes/:id
        def update
          enforce_permission_to :update, :candidacy_type_scope, candidacy_type_scope: current_candidacy_type_scope
          @form = candidacy_type_scope_form.from_params(params)

          UpdateCandidacyTypeScope.call(@form, current_candidacy_type_scope) do
            on(:ok) do
              flash[:notice] = I18n.t("decidim.signature_collection.admin.candidacies_type_scopes.update.success")
              redirect_to edit_candidacies_type_path(resource.type)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("decidim.signature_collection.admin.candidacies_type_scopes.update.error")
              render :edit
            end
          end
        end

        # DELETE /admin/candidacies_types/:candidacies_type_id/candidacies_type_scopes/:id
        def destroy
          enforce_permission_to :destroy, :candidacy_type_scope, candidacy_type_scope: current_candidacy_type_scope
          current_candidacy_type_scope.destroy!

          redirect_to edit_candidacies_type_path(current_candidacy_type_scope.type), flash: {
            notice: I18n.t("decidim.signature_collection.admin.candidacies_type_scopes.destroy.success")
          }
        end

        private

        def set_controller_breadcrumb
          controller_breadcrumb_items.append(
            {
              label: translated_attribute(current_candidacy_type.title),
              url: edit_candidacies_type_path(current_candidacy_type),
              active: false
            },
            {
              label: t("candidacy_type_scopes", scope: "decidim.admin.menu"),
              active: true
            }
          )

          if params[:id].present?
            controller_breadcrumb_items << {
              label: translated_attribute(current_candidacy_type_scope.scope_name),
              active: true
            }
          end
        end

        def current_candidacy_type_scope
          @current_candidacy_type_scope ||= CandidaciesTypeScope.joins(:type).where(decidim_signature_collection_candidacies_types: { organization: current_organization }).find(params[:id])
        end

        def current_candidacy_type
          @current_candidacy_type ||= CandidaciesType.find(params[:candidacies_type_id])
        end

        def candidacy_type_scope_form
          form(Decidim::SignatureCollection::Admin::CandidacyTypeScopeForm)
        end
      end
    end
  end
end
