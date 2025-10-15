# frozen_string_literal: true

module Decidim
  module Candidacies
    class CandidacysMailerPreview < ActionMailer::Preview
      def notify_creation
        candidacy = Decidim::Candidacy.first
        Decidim::Candidacies::CandidacysMailer.notify_creation(candidacy)
      end

      def notify_progress
        candidacy = Decidim::Candidacy.first
        Decidim::Candidacies::CandidacysMailer.notify_progress(candidacy, candidacy.author)
      end

      def notify_state_change_to_published
        candidacy = Decidim::Candidacy.first
        candidacy.state = "published"
        Decidim::Candidacies::CandidacysMailer.notify_state_change(candidacy, candidacy.author)
      end

      def notify_state_change_to_discarded
        candidacy = Decidim::Candidacy.first
        candidacy.state = "discarded"
        Decidim::Candidacies::CandidacysMailer.notify_state_change(candidacy, candidacy.author)
      end

      def notify_state_change_to_accepted
        candidacy = Decidim::Candidacy.first
        candidacy.state = "accepted"
        Decidim::Candidacies::CandidacysMailer.notify_state_change(candidacy, candidacy.author)
      end

      def notify_state_change_to_rejected
        candidacy = Decidim::Candidacy.first
        candidacy.state = "rejected"
        Decidim::Candidacies::CandidacysMailer.notify_state_change(candidacy, candidacy.author)
      end
    end
  end
end
