# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # Controller used to manage the candidacies answers
      class AnswersController < Decidim::Candidacies::Admin::ApplicationController
        include Decidim::Candidacies::NeedsCandidacy
        include Decidim::Admin::ParticipatorySpaceAdminBreadcrumb

        add_breadcrumb_item_from_menu :admin_candidacy_actions_menu

        helper Decidim::Candidacies::CandidacyHelper
        layout "decidim/admin/candidacies"

        # GET /admin/candidacies/:id/answer/edit
        def edit
          enforce_permission_to :answer, :candidacy, candidacy: current_candidacy
          @form = form(Decidim::Candidacies::Admin::CandidacyAnswerForm)
                  .from_model(
                    current_candidacy,
                    candidacy: current_candidacy
                  )
        end

        # PUT /admin/candidacies/:id/answer
        def update
          enforce_permission_to :answer, :candidacy, candidacy: current_candidacy

          @form = form(Decidim::Candidacies::Admin::CandidacyAnswerForm)
                  .from_params(params, candidacy: current_candidacy)

          UpdateCandidacyAnswer.call(current_candidacy, @form) do
            on(:ok) do
              flash[:notice] = I18n.t("candidacies.update.success", scope: "decidim.candidacies.admin")
              redirect_to candidacies_path
            end

            on(:invalid) do
              flash[:alert] = I18n.t("candidacies.update.error", scope: "decidim.candidacies.admin")
              redirect_to edit_candidacy_answer_path
            end
          end
        end
      end
    end
  end
end
