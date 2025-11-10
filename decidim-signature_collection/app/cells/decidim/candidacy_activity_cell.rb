# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # A cell to display when an candidacy has been published.
    class CandidacyActivityCell < ActivityCell
      def title
        I18n.t "decidim.signature_collection.last_activity.new_candidacy"
      end
    end
  end
end
