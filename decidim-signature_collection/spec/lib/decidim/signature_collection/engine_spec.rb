# frozen_string_literal: true

require "spec_helper"

describe Decidim::SignatureCollection::Engine do
  it_behaves_like "clean engine"

  it "loads engine mailer previews" do
    expect(ActionMailer::Preview.all).to include(Decidim::Candidacies::CandidaciesMailerPreview)
  end

  describe "decidim_signature_collection.authorization_transfer" do
    include_context "authorization transfer"

    let(:component) { create(:post_component, organization:) }
    let(:original_records) do
      {
        candidacies: create_list(:candidacy, 3, organization:, author: original_user),
        votes: create_list(:candidacy_user_vote, 5, author: original_user)
      }
    end
    let(:transferred_candidacies) { Decidim::SignatureCollection::Candidacy.where(author: target_user).order(:id) }
    let(:transferred_votes) { Decidim::SignatureCollection::CandidaciesVote.where(author: target_user).order(:id) }

    it "handles authorization transfer correctly" do
      expect(transferred_candidacies.count).to eq(3)
      expect(transferred_votes.count).to eq(5)
      expect(transfer.records.count).to eq(8)
      expect(transferred_resources).to eq(transferred_candidacies + transferred_votes)
    end
  end
end
