# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # Controller in charge of managing committee membership
      class CommitteeRequestsController < Decidim::SignatureCollection::Admin::ApplicationController
        include CandidacyAdmin

        add_breadcrumb_item_from_menu :admin_candidacy_menu

        # GET /admin/candidacies/:candidacy_id/committee_requests
        def index
          enforce_permission_to :index, :candidacy_committee_member
        end

        # GET /candidacies/:candidacy_id/committee_requests/:id/approve
        def approve
          enforce_permission_to :approve, :candidacy_committee_member, request: membership_request

          ApproveMembershipRequest.call(membership_request) do
            on(:ok) do
              redirect_to edit_candidacy_path(current_candidacy), flash: {
                notice: I18n.t("success", scope: "decidim.signature_collection.committee_requests.approve")
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
                notice: I18n.t("success", scope: "decidim.signature_collection.committee_requests.revoke")
              }
            end
          end
        end

        private

        def membership_request
          @membership_request ||= CandidaciesCommitteeMember.where(candidacy: current_participatory_space).find(params[:id])
        end
      end
    end
  end
end
