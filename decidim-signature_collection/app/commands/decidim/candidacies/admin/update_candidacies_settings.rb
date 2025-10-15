# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # A command with all the business logic when updating candidacies
      # settings in admin area.
      class UpdateCandidacysSettings < Decidim::Commands::UpdateResource
        fetch_form_attributes :candidacies_order, :creation_enabled
      end
    end
  end
end
