# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe CandidacysVote do
    let(:vote) { build(:candidacy_user_vote) }

    it "is valid" do
      expect(vote).to be_valid
    end
  end
end
