# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe UnvoteCandidacy, skip: "Awaiting review" do

      describe "User unvotes candidacy" do
        let(:vote) { create(:candidacy_user_vote) }
        let(:command) { described_class.new(vote.candidacy, vote.author) }

        it "broadcasts ok" do
          expect(vote).to be_valid
          expect { command.call }.to broadcast :ok
        end

        it "Removes the vote" do
          expect(vote).to be_valid
          expect do
            command.call
          end.to change(CandidaciesVote, :count).by(-1)
        end

        it "decreases the vote counter by one" do
          candidacy = vote.candidacy
          expect(CandidaciesVote.count).to eq(1)
          expect do
            command.call
            candidacy.reload
          end.to change { candidacy.online_votes_count }.by(-1)
        end
      end
    end
  end
end
