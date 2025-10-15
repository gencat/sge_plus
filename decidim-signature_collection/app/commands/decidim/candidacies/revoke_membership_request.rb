# frozen_string_literal: true

module Decidim
  module Candidacies
    # A command with all the business logic that creates a new candidacy.
    class RevokeMembershipRequest < Decidim::Command
      # Public: Initializes the command.
      #
      # membership_request - A pending committee member
      def initialize(membership_request)
        @membership_request = membership_request
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      #
      # Returns nothing.
      def call
        @membership_request.rejected!
        notify_applicant

        broadcast(:ok, @membership_request)
      end

      private

      def notify_applicant
        Decidim::EventsManager.publish(
          event: "decidim.events.candidacies.revoke_membership_request",
          event_class: Decidim::Candidacies::RevokeMembershipRequestEvent,
          resource: @membership_request.candidacy,
          affected_users: [@membership_request.user],
          force_send: true,
          extra: { author: { id: @membership_request.candidacy.author&.id } }
        )
      end
    end
  end
end
