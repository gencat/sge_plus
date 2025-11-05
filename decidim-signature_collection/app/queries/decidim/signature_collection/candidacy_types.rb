# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Class uses to retrieve the available candidacy types.
    class CandidacyTypes < Decidim::Query
      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # organization - Decidim::Organization
      def self.for(organization)
        new(organization).query
      end

      # Initializes the class.
      #
      # organization - Decidim::Organization
      def initialize(organization)
        @organization = organization
      end

      # Retrieves the available candidacy types for the given organization.
      def query
        CandidaciesType.where(organization: @organization)
      end
    end
  end
end
