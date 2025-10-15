# frozen_string_literal: true

module Decidim
  module Candidacies
    # A presenter to render statistics in the homepage.
    class CandidacyStatsPresenter < SimpleDelegator
      def candidacy
        __getobj__.fetch(:candidacy)
      end

      def comments_count
        Rails.cache.fetch(
          "candidacy/#{candidacy.id}/comments_count",
          expires_in: Decidim::Candidacies.stats_cache_expiration_time
        ) do
          candidacy.comments_count
        end
      end

      def meetings_count
        Rails.cache.fetch(
          "candidacy/#{candidacy.id}/meetings_count",
          expires_in: Decidim::Candidacies.stats_cache_expiration_time
        ) do
          Decidim::Meetings::Meeting.where(component: meetings_component).count
        end
      end

      def assistants_count
        Rails.cache.fetch(
          "candidacy/#{candidacy.id}/assistants_count",
          expires_in: Decidim::Candidacies.stats_cache_expiration_time
        ) do
          result = 0
          Decidim::Meetings::Meeting.where(component: meetings_component).each do |meeting|
            result += meeting.attendees_count || 0
          end

          result
        end
      end

      private

      def meetings_component
        @meetings_component ||= Decidim::Component.find_by(participatory_space: candidacy, manifest_name: "meetings")
      end
    end
  end
end
