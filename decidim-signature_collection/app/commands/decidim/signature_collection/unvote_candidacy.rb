# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # A command with all the business logic when a user or organization unvotes an candidacy.
    class UnvoteCandidacy < Decidim::Command
      # Public: Initializes the command.
      #
      # candidacy   - A Decidim::SignatureCollection::Candidacy object.
      # current_user - The current user.
      def initialize(candidacy, current_user)
        @candidacy = candidacy
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the candidacy.
      # - :invalid if the form was not valid and we could not proceed.
      #
      # Returns nothing.
      def call
        destroy_candidacy_vote
        broadcast(:ok, @candidacy)
      end

      private

      def destroy_candidacy_vote
        Candidacy.transaction do
          @candidacy.votes.where(author: @current_user).destroy_all
        end
      end
    end
  end
end
