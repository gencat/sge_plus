# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Service that reports changes in candidacy status
    class StatusChangeNotifier
      attr_reader :candidacy

      def initialize(args = {})
        @candidacy = args.fetch(:candidacy)
      end

      # PUBLIC
      # Notifies when an candidacy has changed its status.
      #
      # * created: Notifies the author that their candidacy has been created.
      #
      # * validating: Administrators will be notified about the candidacy that
      #   requests technical validation.
      #
      # * published, discarded: Candidacy authors will be notified about the
      #   result of the technical validation process.
      #
      # * rejected, accepted: Candidacy's followers and authors will be
      #   notified about the result of the candidacy.
      def notify
        notify_candidacy_creation if candidacy.created?
        notify_validating_candidacy if candidacy.validating?
        notify_validating_result if candidacy.published? || candidacy.discarded?
        notify_support_result if candidacy.rejected? || candidacy.accepted?
      end

      private

      def notify_candidacy_creation
        Decidim::SignatureCollection::CandidaciesMailer
          .notify_creation(candidacy)
          .deliver_later
      end

      # Does nothing
      def notify_validating_candidacy
        # It has been moved into SendCandidacyToTechnicalValidation command as a standard notification
        # It would be great to move the functionality of this class, which is invoked on Candidacy#after_save,
        # to the corresponding commands to follow the architecture of Decidim.
      end

      def notify_validating_result
        candidacy.committee_members.approved.each do |committee_member|
          Decidim::SignatureCollection::CandidaciesMailer
            .notify_state_change(candidacy, committee_member.user)
            .deliver_later
        end

        Decidim::SignatureCollection::CandidaciesMailer
          .notify_state_change(candidacy, candidacy.author)
          .deliver_later
      end

      def notify_support_result
        candidacy.followers.each do |follower|
          Decidim::SignatureCollection::CandidaciesMailer
            .notify_state_change(candidacy, follower)
            .deliver_later
        end

        candidacy.committee_members.approved.each do |committee_member|
          Decidim::SignatureCollection::CandidaciesMailer
            .notify_state_change(candidacy, committee_member.user)
            .deliver_later
        end

        Decidim::SignatureCollection::CandidaciesMailer
          .notify_state_change(candidacy, candidacy.author)
          .deliver_later
      end
    end
  end
end
