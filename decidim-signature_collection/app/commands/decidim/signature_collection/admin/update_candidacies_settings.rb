# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A command with all the business logic when updating candidacies
      # settings in admin area.
      class UpdateCandidaciesSettings < Decidim::Commands::UpdateResource
        fetch_form_attributes :candidacies_order, :creation_enabled
      end
    end
  end
end
