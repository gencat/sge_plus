# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # A form object used to create candidacies settings from the admin dashboard.
      class CandidacysSettingsForm < Form
        mimic :candidacies_settings

        attribute :candidacies_order, String
        attribute :creation_enabled, Boolean, default: true
      end
    end
  end
end
