# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # Controller used to manage the candidacies answers
      class AnswersController < Decidim::SignatureCollection::Admin::ApplicationController
        include Decidim::SignatureCollection::NeedsCandidacy
        include Decidim::Admin::ParticipatorySpaceAdminBreadcrumb

        add_breadcrumb_item_from_menu :admin_candidacy_actions_menu

        helper Decidim::SignatureCollection::CandidacyHelper
        layout "decidim/admin/signature_collection/candidacies"

        # GET /admin/candidacies/:id/answer/edit
        def edit
          enforce_permission_to :answer, :candidacy, candidacy: current_candidacy
          @form = form(Decidim::SignatureCollection::Admin::CandidacyAnswerForm)
                  .from_model(
                    current_candidacy,
                    candidacy: current_candidacy
                  )
        end

        # PUT /admin/candidacies/:id/answer
        def update
          enforce_permission_to :answer, :candidacy, candidacy: current_candidacy

          @form = form(Decidim::SignatureCollection::Admin::CandidacyAnswerForm)
                  .from_params(params, candidacy: current_candidacy)

          UpdateCandidacyAnswer.call(current_candidacy, @form) do
            on(:ok) do
              flash[:notice] = I18n.t("candidacies.update.success", scope: "decidim.signature_collection.admin")
              redirect_to candidacies_path
            end

            on(:invalid) do
              flash[:alert] = I18n.t("candidacies.update.error", scope: "decidim.signature_collection.admin")
              redirect_to edit_candidacy_answer_path
            end
          end
        end
      end
    end
  end
end
