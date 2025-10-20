# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    # describe CandidacyEndorsementGenerator do
    #   context "with a candidacy and an endorser user" do
    #     let(:organization) { create(:organization) }
    #     let(:author) { create(:user, organization:) }
    #     let(:candidacy) do
    #       double(
    #         "candidacy",
    #         title: { en: "Candidacy Title" },
    #         author:,
    #         followers: [],
    #         committee_members: double("committee_members", approved: [])
    #       )
    #     end
    #     let(:endorser) { create(:user, :confirmed, organization:) }

    #     let(:generator) { described_class.new(candidacy:, endorser:) }

    #     describe "#call" do
    #       it "creates a new endorsement for the candidacy by the endorser" do
    #         expect { generator.call }.to change { candidacy.endorsements.count }.by(1)
    #         endorsement = candidacy.endorsements.last
    #         expect(endorsement.user).to eq(endorser)
    #       end

    #       it "returns the created endorsement" do
    #         endorsement = generator.call
    #         expect(endorsement).to be_a(Decidim::Endorsements::Endorsement)
    #         expect(endorsement.candidacy).to eq(candidacy)
    #         expect(endorsement.user).to eq(endorser)
    #       end
    #     end
    #   end
    # end
  end
end
