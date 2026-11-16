# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Retrieves the open online candidacies whose type signature period has finished.
    class SupportPeriodFinishedCandidacies < Decidim::Query
      # Retrieves the candidacies ready to be evaluated to decide if they have been
      # accepted or not.
      def query
        Decidim::SignatureCollection::Candidacy
          .joins(scoped_type: :type)
          .where(state: "open")
          .where(signature_type: "online")
          .where(decidim_signature_collection_candidacies_types: { signature_period_end: ...Time.current })
      end
    end
  end
end
