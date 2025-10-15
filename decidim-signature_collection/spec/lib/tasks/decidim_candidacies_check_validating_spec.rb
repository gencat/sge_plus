# frozen_string_literal: true

require "spec_helper"

describe "decidim_candidacies:check_validating", type: :task do
  let(:threshold) { Time.current - Decidim::Candidacies.max_time_in_validating_state }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "runs gracefully" do
    expect { task.execute }.not_to raise_error
  end

  context "when candidacies without changes" do
    let(:candidacy) { create(:candidacy, :validating, updated_at: 1.year.ago) }

    it "Are marked as discarded" do
      expect(candidacy.updated_at).to be < threshold
      task.execute

      candidacy.reload
      expect(candidacy).to be_discarded
    end
  end

  context "when candidacies with changes" do
    let(:candidacy) { create(:candidacy, :validating) }

    it "remain unchanged" do
      expect(candidacy.updated_at).to be >= threshold
      task.execute

      candidacy.reload
      expect(candidacy).to be_validating
    end
  end
end
