# frozen_string_literal: true

module Decidim
  module SignatureCollection
    class ExtendCandidacyEvent < Decidim::Events::SimpleEvent
      def participatory_space
        resource
      end
    end
  end
end
