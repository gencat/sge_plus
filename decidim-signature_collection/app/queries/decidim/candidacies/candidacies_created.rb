# frozen_string_literal: true

module Decidim
  module Candidacies
    # Class uses to retrieve the candidacies created by the given user.
    class CandidacysCreated < Decidim::Query
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

      # Retrieves the candidacies created by the given user
      def query
        Candidacy.where(author: user)
      end
    end
  end
end
