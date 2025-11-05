# frozen_string_literal: true

namespace :decidim_candidacies do
  desc "Checks validating candidacies and moves all without changes for a configured time to discarded state"
  task check_validating: :environment do
    Decidim::SignatureCollection::OutdatedValidatingCandidacies
      .for(Decidim::SignatureCollection.max_time_in_validating_state)
      .each(&:discarded!)
  end

  desc "Checks published candidacies and moves to accepted/rejected state depending on the votes collected when the signing period has finished"
  task check_published: :environment do
    Decidim::SignatureCollection::SupportPeriodFinishedCandidacies.new.each do |candidacy|
      if candidacy.supports_goal_reached?
        candidacy.accepted!
      else
        candidacy.rejected!
      end
    end
  end

  desc "Notifies progress on published candidacies"
  task notify_progress: :environment do
    Decidim::SignatureCollection::Candidacy
      .published
      .where.not(first_progress_notification_at: nil)
      .where(second_progress_notification_at: nil).find_each do |candidacy|
      if candidacy.percentage >= Decidim::SignatureCollection.second_notification_percentage
        notifier = Decidim::SignatureCollection::ProgressNotifier.new(candidacy:)
        notifier.notify

        candidacy.second_progress_notification_at = Time.now.utc
        candidacy.save
      end
    end

    Decidim::SignatureCollection::Candidacy
      .published
      .where(first_progress_notification_at: nil).find_each do |candidacy|
      if candidacy.percentage >= Decidim::SignatureCollection.first_notification_percentage
        notifier = Decidim::SignatureCollection::ProgressNotifier.new(candidacy:)
        notifier.notify

        candidacy.first_progress_notification_at = Time.now.utc
        candidacy.save
      end
    end
  end
end
