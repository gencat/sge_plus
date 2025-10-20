# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # Controller that allows managing the Candidacy's Component
      # permissions in the admin panel.
      class ComponentPermissionsController < Decidim::Admin::ComponentPermissionsController
        include CandidacyAdmin
      end
    end
  end
end
