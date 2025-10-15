# frozen_string_literal: true

module Decidim
  module Candidacies
    # Controller in charge of managing committee membership
    class CommitteeRequestsController < Decidim::Candidacies::ApplicationController
      include Decidim::Candidacies::NeedsCandidacy

      helper CandidacyHelper
      helper Decidim::ActionAuthorizationHelper

      # GET /candidacies/:candidacy_id/committee_requests/new
      def new
        enforce_permission_to :request_membership, :candidacy, candidacy: current_candidacy
      end

      # GET /candidacies/:candidacy_id/committee_requests/spawn
      def spawn
        enforce_permission_to :request_membership, :candidacy, candidacy: current_candidacy

        form = Decidim::Candidacies::CommitteeMemberForm
               .from_params(candidacy_id: current_candidacy.id, user_id: current_user.id, state: "requested")
               .with_context(current_organization: current_candidacy.organization, current_user:)

        SpawnCommitteeRequest.call(form) do
          on(:ok) do
            redirect_to candidacies_path, flash: {
              notice: I18n.t(
                "success",
                scope: "decidim.candidacies.committee_requests.spawn"
              )
            }
          end

          on(:invalid) do |request|
            redirect_to candidacies_path, flash: {
              error: request.errors.full_messages.to_sentence
            }
          end
        end
      end

      # GET /candidacies/:candidacy_id/committee_requests/:id/approve
      def approve
        enforce_permission_to :approve, :candidacy_committee_member, request: membership_request

        ApproveMembershipRequest.call(membership_request) do
          on(:ok) do
            redirect_to edit_candidacy_path(current_candidacy), flash: {
              notice: I18n.t("success", scope: "decidim.candidacies.committee_requests.approve")
            }
          end
        end
      end

      # DELETE /candidacies/:candidacy_id/committee_requests/:id/revoke
      def revoke
        enforce_permission_to :revoke, :candidacy_committee_member, request: membership_request

        RevokeMembershipRequest.call(membership_request) do
          on(:ok) do
            redirect_to edit_candidacy_path(current_candidacy), flash: {
              notice: I18n.t("success", scope: "decidim.candidacies.committee_requests.revoke")
            }
          end
        end
      end

      private

      def membership_request
        @membership_request ||= CandidacysCommitteeMember.where(candidacy: current_participatory_space).find(params[:id])
      end
    end
  end
end
