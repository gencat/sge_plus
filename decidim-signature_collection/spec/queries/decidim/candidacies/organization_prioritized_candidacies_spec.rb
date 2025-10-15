# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    describe OrganizationPrioritizedCandidacys do
      subject { described_class.new(organization, order) }

      let(:organization) { create(:organization) }
      let!(:user) { create(:user, :confirmed, organization:) }
      let!(:candidacies) { create_list(:candidacy, 5, organization:) }
      let!(:most_recent_candidacy) { create(:candidacy, published_at: 1.day.from_now, organization:) }

      context "when querying by default order" do
        let(:order) { "default" }

        it "returns candidacies ordered by least recent" do
          expect(subject.count).to eq(6)
          expect(subject.query.last).to eq(most_recent_candidacy)
        end
      end

      context "when querying by most recent order" do
        let(:order) { "most_recent" }

        it "returns candidacies ordered by most recent" do
          expect(subject.count).to eq(6)
          expect(subject.query.first).to eq(most_recent_candidacy)
        end
      end
    end
  end
end
