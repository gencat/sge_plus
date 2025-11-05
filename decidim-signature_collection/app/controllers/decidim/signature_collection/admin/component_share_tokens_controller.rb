# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # This controller allows sharing unpublished things.
      # It is targeted for customizations for sharing unpublished things that lives under
      # an candidacy.
      class ComponentShareTokensController < Decidim::Admin::ShareTokensController
        include CandidacyAdmin

        def resource
          @resource ||= current_participatory_space.components.find(params[:component_id])
        end
      end
    end
  end
end
