# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # This query retrieves the organization prioritized candidacies that will appear in the homepage
    class OrganizationPrioritizedCandidacies < Decidim::Query
      attr_reader :organization, :order

      def initialize(organization, order)
        @organization = organization
        @order = order
      end

      def query
        if order == "most_recent"
          base_query.order_by_most_recently_published
        else
          base_query
        end
      end

      private

      def base_query
        Decidim::SignatureCollection::Candidacy.where(organization:).published.open
      end
    end
  end
end
