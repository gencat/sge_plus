# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # Controller that allows managing the Candidacy's Component
      # permissions in the admin panel.
      class ComponentPermissionsController < Decidim::Admin::ComponentPermissionsController
        include CandidacyAdmin
      end
    end
  end
end
