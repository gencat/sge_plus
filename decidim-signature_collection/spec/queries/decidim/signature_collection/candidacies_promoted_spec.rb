# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidaciesPromoted do
      let!(:user) { create(:user, :confirmed, organization:) }
      let!(:admin) { create(:user, :confirmed, :admin, organization:) }
      let!(:organization) { create(:organization) }
      let!(:user_candidacies) { create_list(:candidacy, 3, organization:, author: user) }
      let!(:admin_candidacies) { create_list(:candidacy, 3, organization:, author: admin) }

      context "when candidacy promoters" do
        subject { described_class.new(promoter) }

        let(:promoter) { create(:user, organization:) }
        let(:promoter_candidacies) { create_list(:candidacy, 3, organization:) }

        before do
          promoter_candidacies.each do |candidacy|
            create(:candidacies_committee_member, candidacy:, user: promoter)
          end
        end

        it "includes only promoter candidacies" do
          expect(subject).to include(*promoter_candidacies)
          expect(subject).not_to include(*user_candidacies)
          expect(subject).not_to include(*admin_candidacies)
        end
      end
    end
  end
end
