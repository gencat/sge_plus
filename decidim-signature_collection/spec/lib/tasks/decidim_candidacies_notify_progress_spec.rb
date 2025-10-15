# frozen_string_literal: true

require "spec_helper"

describe "decidim_candidacies:notify_progress", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "runs gracefully" do
    expect { task.execute }.not_to raise_error
  end

  context "when candidacy without supports" do
    let(:candidacy) { create(:candidacy) }

    it "Keeps candidacy unchanged" do
      expect(candidacy.online_votes_count).to be_zero

      task.execute
      expect(candidacy.first_progress_notification_at).to be_nil
      expect(candidacy.second_progress_notification_at).to be_nil
    end

    it "do not invokes the mailer" do
      expect(Decidim::Candidacies::CandidacysMailer).not_to receive(:notify_progress)
      task.execute
    end
  end

  context "when candidacy ready for first notification" do
    let(:candidacy) do
      candidacy = create(:candidacy)

      votes_needed = (candidacy.supports_required * (Decidim::Candidacies.first_notification_percentage / 100.0)) + 1
      candidacy.online_votes["total"] = votes_needed
      candidacy.save!

      candidacy
    end

    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(message_delivery).to receive(:deliver_later)
    end

    it "updates notification time" do
      expect(candidacy.percentage).to be >= Decidim::Candidacies.first_notification_percentage
      expect(candidacy.percentage).to be < Decidim::Candidacies.second_notification_percentage

      task.execute

      candidacy.reload
      expect(candidacy.first_progress_notification_at).not_to be_nil
      expect(candidacy.second_progress_notification_at).to be_nil
    end

    it "invokes the mailer" do
      expect(candidacy.percentage).to be >= Decidim::Candidacies.first_notification_percentage
      expect(candidacy.percentage).to be < Decidim::Candidacies.second_notification_percentage

      expect(Decidim::Candidacies::CandidacysMailer).to receive(:notify_progress)
        .at_least(:once)
        .and_return(message_delivery)
      task.execute
    end
  end

  context "when candidacy ready for second notification" do
    let(:candidacy) do
      candidacy = create(:candidacy, first_progress_notification_at: Time.current)

      votes_needed = (candidacy.supports_required * (Decidim::Candidacies.second_notification_percentage / 100.0)) + 1

      candidacy.online_votes["total"] = votes_needed
      candidacy.save!

      candidacy
    end

    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(message_delivery).to receive(:deliver_later)
    end

    it "updates notification time" do
      expect(candidacy.percentage).to be >= Decidim::Candidacies.second_notification_percentage

      task.execute

      candidacy.reload
      expect(candidacy.second_progress_notification_at).not_to be_nil
    end

    it "invokes the mailer" do
      expect(candidacy.percentage).to be >= Decidim::Candidacies.second_notification_percentage
      expect(Decidim::Candidacies::CandidacysMailer).to receive(:notify_progress)
        .at_least(:once)
        .and_return(message_delivery)
      task.execute
    end
  end

  context "when candidacy with both notifications sent" do
    let(:candidacy) do
      create(:candidacy,
             first_progress_notification_at: Time.current,
             second_progress_notification_at: Time.current)
    end

    it "do not invokes the mailer" do
      expect(Decidim::Candidacies::CandidacysMailer).not_to receive(:notify_progress)
      task.execute
    end
  end
end
