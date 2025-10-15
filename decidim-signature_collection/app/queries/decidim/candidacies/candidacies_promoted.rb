# frozen_string_literal: true

module Decidim
  module Candidacies
    # Class uses to retrieve candidacies promoted by the given  user
    class CandidacysPromoted < Decidim::Query
      attr_reader :user

      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # user - Decidim::User
      def self.by(user)
        new(user).query
      end

      # Initializes the class.
      #
      # user: Decidim::User
      def initialize(user)
        @user = user
      end

      # Retrieves the candidacies promoted by the  given  user.
      def query
        Candidacy
          .joins(:committee_members)
          .where("decidim_candidacies_committee_members.state = 2")
          .where(decidim_candidacies_committee_members: { decidim_users_id: user.id })
      end
    end
  end
end
