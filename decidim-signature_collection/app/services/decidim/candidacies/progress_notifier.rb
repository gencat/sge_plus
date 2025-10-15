# frozen_string_literal: true

module Decidim
  module Candidacies
    # Service that notifies progress for an candidacy
    class ProgressNotifier
      attr_reader :candidacy

      def initialize(args = {})
        @candidacy = args.fetch(:candidacy)
      end

      # PUBLIC: Notifies the support progress of the candidacy.
      #
      # Notifies to Candidacy's authors and followers about the
      # number of supports received by the candidacy.
      def notify
        candidacy.followers.each do |follower|
          Decidim::Candidacies::CandidacysMailer
            .notify_progress(candidacy, follower)
            .deliver_later
        end

        candidacy.committee_members.approved.each do |committee_member|
          Decidim::Candidacies::CandidacysMailer
            .notify_progress(candidacy, committee_member.user)
            .deliver_later
        end

        Decidim::Candidacies::CandidacysMailer
          .notify_progress(candidacy, candidacy.author)
          .deliver_later
      end
    end
  end
end
