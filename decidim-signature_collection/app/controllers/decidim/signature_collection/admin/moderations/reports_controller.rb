# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      module Moderations
        # This controller allows admins to manage moderation reports in an candidacy.
        class ReportsController < Decidim::Admin::Moderations::ReportsController
          include CandidacyAdmin

          def permissions_context
            super.merge(current_participatory_space:)
          end
        end
      end
    end
  end
end
