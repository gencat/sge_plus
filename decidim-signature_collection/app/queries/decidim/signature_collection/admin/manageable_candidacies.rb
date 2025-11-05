# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # Class that retrieves manageable candidacies for the given user.
      # Regular users will get only their candidacies. Administrators will
      # retrieve all candidacies.
      class ManageableCandidacies < Decidim::Query
        # Syntactic sugar to initialize the class and return the queried objects
        #
        # user - Decidim::User
        def self.for(user)
          new(user).query
        end

        # Initializes the class.
        #
        # user - Decidim::User
        def initialize(user)
          @user = user
        end

        # Retrieves all candidacies / Candidacies created by the user.
        def query
          return Candidacy.where(organization: @user.organization) if @user.admin?

          Candidacy.where(id: CandidaciesCreated.by(@user) + CandidaciesPromoted.by(@user))
        end
      end
    end
  end
end
