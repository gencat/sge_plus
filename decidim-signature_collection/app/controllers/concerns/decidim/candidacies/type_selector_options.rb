# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Candidacies
    # Common logic for elements that need to be able to select candidacy types.
    module TypeSelectorOptions
      extend ActiveSupport::Concern

      include Decidim::TranslationsHelper

      included do
        helper_method :available_candidacy_types, :candidacy_type_options,
                      :candidacy_types_each

        private

        # Return all candidacy types with scopes defined.
        def available_candidacy_types
          Decidim::Candidacies::CandidacyTypes
            .for(current_organization)
            .joins(:scopes)
            .where(published: true)
            .distinct
        end

        def candidacy_type_options
          available_candidacy_types.map do |type|
            [type.title[I18n.locale.to_s], type.id]
          end
        end

        def candidacy_types_each
          available_candidacy_types.each do |type|
            yield(type)
          end
        end
      end
    end
  end
end
