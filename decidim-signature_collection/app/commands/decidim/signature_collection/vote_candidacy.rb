# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # A command with all the business logic when a user or organization votes an candidacy.
    class VoteCandidacy < Decidim::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(form)
        @form = form
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the proposal vote.
      # - :invalid if the form was not valid and we could not proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        percentage_before = candidacy.percentage
        vote = nil

        Candidacy.transaction do
          vote = create_vote
        end

        percentage_after = candidacy.reload.percentage

        send_notification
        notify_percentage_change(percentage_before, percentage_after)
        notify_support_threshold_reached(percentage_before, percentage_after)

        broadcast(:ok, vote)
      end

      private

      attr_reader :form

      delegate :candidacy, to: :form

      def create_vote
        vote = Decidim::SignatureCollection::CandidaciesVote.new(
          candidacy:,
          encrypted_xml_doc_to_sign: form.encrypted_xml_doc_to_sign,
          filename: form.filename,
          hash_id: form.hash_id
        )
        candidacy.votes.build(vote.attributes).save!

        vote
      end

      def timestamp
        return unless timestamp_service

        @timestamp ||= timestamp_service.new(document: form.encrypted_metadata).timestamp
      end

      def timestamp_service
        @timestamp_service ||= Decidim.timestamp_service.to_s.safe_constantize
      end

      def send_notification
        Decidim::EventsManager.publish(
          event: "decidim.events.signature_collection.candidacy_endorsed",
          event_class: Decidim::SignatureCollection::EndorseCandidacyEvent,
          resource: candidacy,
          followers: candidacy.author.followers
        )
      end

      def notify_percentage_change(before, after)
        percentage = [25, 50, 75, 100].find do |milestone|
          before < milestone && after >= milestone
        end

        return unless percentage

        Decidim::EventsManager.publish(
          event: "decidim.events.milestone_completed",
          event_class: Decidim::SignatureCollection::MilestoneCompletedEvent,
          resource: candidacy,
          affected_users: [candidacy.author],
          followers: candidacy.followers - [candidacy.author],
          extra: {
            percentage:
          }
        )
      end

      def notify_support_threshold_reached(before, after)
        # Do not need to notify if threshold has already been reached
        return if before == after || after != 100

        Decidim::EventsManager.publish(
          event: "decidim.events.support_threshold_reached",
          event_class: Decidim::SignatureCollection::Admin::SupportThresholdReachedEvent,
          resource: candidacy,
          followers: candidacy.organization.admins
        )
      end
    end
  end
end
