# frozen_string_literal: true

module Decidim
  module SignatureCollection
    class EndorseCandidacyEvent < Decidim::Events::SimpleEvent
      include Decidim::Events::AuthorEvent

      def i18n_scope
        "decidim.signature_collection.events.endorse_candidacy_event"
      end
    end
  end
end
