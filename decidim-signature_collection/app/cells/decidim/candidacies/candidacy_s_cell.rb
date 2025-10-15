# frozen_string_literal: true

module Decidim
  module Candidacies
    # This cell renders the Search (:s) candidacy card
    # for a given instance of an Candidacy
    class CandidacySCell < Decidim::CardSCell
      private

      def metadata_cell
        "decidim/candidacies/candidacy_metadata_g"
      end
    end
  end
end
