# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe UnvoteCandidacy do
      describe "User unvotes candidacy" do
        let!(:vote) { create(:candidacy_user_vote, :signed) }
        let(:candidacy) { vote.candidacy }
        let(:command) { described_class.new(candidacy, candidacy.author) }

        # Votes no longer have an author (removed in 20251222131109), so the vote of the user cannot be found.
        it "raises an error" do
          expect { command.call }.to raise_error(ActiveRecord::StatementInvalid, /UndefinedColumn/)
        end

        it "keeps the vote and the vote counter" do
          expect do
            command.call
          rescue ActiveRecord::StatementInvalid
            nil
          end.not_to(change { [CandidaciesVote.count, candidacy.reload.online_votes_count] }.from([1, 1]))
        end
      end
    end
  end
end
