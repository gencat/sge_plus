# frozen_string_literal: true

module Decidim
  module Candidacies
    class CandidacySerializer < Decidim::Candidacies::OpenDataCandidacySerializer
      # Serializes an candidacy
      def serialize
        super.merge(
          {
            components: serialize_components
          }
        )
      end
    end
  end
end
