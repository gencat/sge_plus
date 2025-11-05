# frozen_string_literal: true

require "spec_helper"

describe "decidim_candidacies:check_published", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "runs gracefully" do
    expect { task.execute }.not_to raise_error
  end

  context "when candidacies with enough votes" do
    let(:candidacy) { create(:candidacy, :acceptable) }

    it "is marked as accepted" do
      expect(candidacy).to be_published

      task.execute
      candidacy.reload
      expect(candidacy).to be_accepted
    end
  end

  context "when candidacies without enough votes" do
    let(:candidacy) { create(:candidacy, :rejectable) }

    it "is marked as rejected" do
      expect(candidacy).to be_published

      task.execute
      candidacy.reload
      expect(candidacy).to be_rejected
    end
  end

  context "when candidacies with presential support enabled" do
    let(:candidacy) { create(:candidacy, :acceptable, signature_type: "offline") }

    it "keeps unchanged" do
      expect(candidacy).to be_published

      task.execute
      candidacy.reload
      expect(candidacy).to be_published
    end
  end

  context "when candidacies with mixed support enabled" do
    let(:candidacy) { create(:candidacy, :acceptable, signature_type: "any") }

    it "keeps unchanged" do
      expect(candidacy).to be_published

      task.execute
      candidacy.reload
      expect(candidacy).to be_published
    end
  end
end
