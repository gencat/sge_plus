# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # This controller allows admins to manage moderations in an candidacy.
      class ModerationsController < Decidim::Admin::ModerationsController
        include CandidacyAdmin

        add_breadcrumb_item_from_menu :admin_candidacy_menu

        def permissions_context
          super.merge(current_participatory_space:)
        end
      end
    end
  end
end
