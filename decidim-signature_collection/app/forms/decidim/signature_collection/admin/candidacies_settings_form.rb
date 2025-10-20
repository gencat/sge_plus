# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A form object used to create candidacies settings from the admin dashboard.
      class CandidaciesSettingsForm < Form
        mimic :candidacies_settings

        attribute :candidacies_order, String
        attribute :creation_enabled, Boolean, default: true
      end
    end
  end
end
