# frozen_string_literal: true

module Decidim
  module SignatureCollection
    class CandidacySerializer < Decidim::SignatureCollection::OpenDataCandidacySerializer
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
