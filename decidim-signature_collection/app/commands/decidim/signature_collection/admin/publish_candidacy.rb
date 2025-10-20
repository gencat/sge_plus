# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A command with all the business logic that publishes an
      # existing candidacy.
      class PublishCandidacy < Decidim::Command
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
          return broadcast(:invalid) if candidacy.published?

          @candidacy = Decidim.traceability.perform_action!(
            :publish,
            candidacy,
            current_user,
            visibility: "all"
          ) do
            candidacy.publish!
            increment_score
            candidacy
          end
          broadcast(:ok, candidacy)
        end

        private

        attr_reader :candidacy, :current_user

        def increment_score
          if candidacy.user_group
            Decidim::Gamification.increment_score(candidacy.user_group, :signature_collection)
          else
            Decidim::Gamification.increment_score(candidacy.author, :signature_collection)
          end
        end
      end
    end
  end
end
