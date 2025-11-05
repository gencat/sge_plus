# frozen_string_literal: true

module Decidim
  module Candidacies
    class CandidaciesMailerPreview < ActionMailer::Preview
      def notify_creation
        candidacy = Decidim::SignatureCollection::Candidacy.first
        Decidim::SignatureCollection::CandidaciesMailer.notify_creation(candidacy)
      end

      def notify_progress
        candidacy = Decidim::SignatureCollection::Candidacy.first
        Decidim::SignatureCollection::CandidaciesMailer.notify_progress(candidacy, candidacy.author)
      end

      def notify_state_change_to_published
        candidacy = Decidim::SignatureCollection::Candidacy.first
        candidacy.state = "published"
        Decidim::SignatureCollection::CandidaciesMailer.notify_state_change(candidacy, candidacy.author)
      end

      def notify_state_change_to_discarded
        candidacy = Decidim::SignatureCollection::Candidacy.first
        candidacy.state = "discarded"
        Decidim::SignatureCollection::CandidaciesMailer.notify_state_change(candidacy, candidacy.author)
      end

      def notify_state_change_to_accepted
        candidacy = Decidim::SignatureCollection::Candidacy.first
        candidacy.state = "accepted"
        Decidim::SignatureCollection::CandidaciesMailer.notify_state_change(candidacy, candidacy.author)
      end

      def notify_state_change_to_rejected
        candidacy = Decidim::SignatureCollection::Candidacy.first
        candidacy.state = "rejected"
        Decidim::SignatureCollection::CandidaciesMailer.notify_state_change(candidacy, candidacy.author)
      end
    end
  end
end
