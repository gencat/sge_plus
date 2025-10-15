# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # A command with all the business logic that unpublishes an
      # existing candidacy.
      class UnpublishCandidacy < Decidim::Command
        # Public: Initializes the command.
        #
        # candidacy - Decidim::Candidacy
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
          return broadcast(:invalid) unless candidacy.published?

          @candidacy = Decidim.traceability.perform_action!(
            :unpublish,
            candidacy,
            current_user
          ) do
            candidacy.unpublish!
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
