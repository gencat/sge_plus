# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A command with all the business logic that discards an
      # existing candidacy.
      class DiscardCandidacy < Decidim::Command
        # Public: Initializes the command.
        #
        # candidacy - Decidim::SignatureCollection::Candidacy
        # current_user - the user performing the action
        def initialize(candidacy, current_user)
          @candidacy = candidacy
          @current_user = current_user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form was not valid and we could not proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if candidacy.discarded?

          @candidacy = Decidim.traceability.perform_action!(:discard, candidacy, current_user) do
            candidacy.discarded!
            candidacy
          end
          broadcast(:ok, candidacy)
        end

        private

        attr_reader :candidacy, :current_user
      end
    end
  end
end
