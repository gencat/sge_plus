# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Class uses to retrieve candidacies that have been a long time in validating
    # state
    class SupportPeriodFinishedCandidacies < Decidim::Query
      # Retrieves the candidacies ready to be evaluated to decide if they have been
      # accepted or not.
      def query
        Decidim::SignatureCollection::Candidacy
          .includes(:scoped_type)
          .where(state: "open")
          .where(signature_type: "online")
          .where(signature_end_date: ...Date.current)
      end
    end
  end
end
