# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # Class that retrieves manageable candidacies for the given user.
      # Regular users will get only their candidacies. Administrators will
      # retrieve all candidacies.
      class ManageableCandidacys < Decidim::Query
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

          Candidacy.where(id: CandidacysCreated.by(@user) + CandidacysPromoted.by(@user))
        end
      end
    end
  end
end
