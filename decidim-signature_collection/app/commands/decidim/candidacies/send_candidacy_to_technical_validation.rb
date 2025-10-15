# frozen_string_literal: true

module Decidim
  module Candidacies
    # A command with all the business logic that sends an
    # existing candidacy to technical validation.
    class SendCandidacyToTechnicalValidation < Decidim::Command
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
        @candidacy = Decidim.traceability.perform_action!(
          :send_to_technical_validation,
          candidacy,
          current_user
        ) do
          candidacy.validating!
          candidacy
        end

        notify_admins

        broadcast(:ok, candidacy)
      end

      private

      attr_reader :candidacy, :current_user

      def notify_admins
        affected_users = Decidim::User.org_admins_except_me(current_user).all

        data = {
          event: "decidim.events.candidacies.candidacy_sent_to_technical_validation",
          event_class: Decidim::Candidacies::CandidacySentToTechnicalValidationEvent,
          resource: candidacy,
          affected_users:,
          force_send: true
        }

        Decidim::EventsManager.publish(**data)
      end
    end
  end
end
