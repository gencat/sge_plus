# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # This controller allows sharing unpublished things.
      # It is targeted for customizations for sharing unpublished things that lives under
      # an candidacy.
      class CandidacyShareTokensController < Decidim::Admin::ShareTokensController
        include CandidacyAdmin

        def resource
          current_candidacy
        end
      end
    end
  end
end
