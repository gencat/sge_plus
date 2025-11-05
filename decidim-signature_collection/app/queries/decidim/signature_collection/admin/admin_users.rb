# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A class used to find the admins for an candidacy or an organization candidacies.
      class AdminUsers < Decidim::Query
        # Syntactic sugar to initialize the class and return the queried objects.
        #
        # candidacy - Decidim::SignatureCollection::Candidacy
        def self.for(candidacy)
          new(candidacy).query
        end

        # Syntactic sugar to initialize the class and return the queried objects.
        #
        # organization - an organization that needs to find its candidacy admins
        def self.for_organization(organization)
          new(nil, organization).query
        end

        # Initializes the class.
        #
        # candidacy - Decidim::SignatureCollection::Candidacy
        # organization - an organization that needs to find its candidacy admins
        def initialize(candidacy, organization = nil)
          @candidacy = candidacy
          @organization = candidacy&.organization || organization
        end

        # Finds organization admins and the users with role admin for the given candidacy.
        #
        # Returns an ActiveRecord::Relation.
        def query
          organization.admins
        end

        private

        attr_reader :candidacy, :organization
      end
    end
  end
end
