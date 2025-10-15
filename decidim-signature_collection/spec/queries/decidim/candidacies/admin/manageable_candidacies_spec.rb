# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    module Admin
      describe ManageableCandidacys do
        subject { described_class.for(user) }

        let!(:organization) { create(:organization) }

        let!(:author) { create(:user, organization:) }
        let!(:promoter) { create(:user, organization:) }
        let!(:admin) { create(:user, :admin, organization:) }

        let!(:author_candidacies) do
          create_list(:candidacy, 3, organization:, author:)
        end
        let!(:promoter_candidacies) do
          create_list(:candidacy, 3, organization:).each do |candidacy|
            create(:candidacies_committee_member, candidacy:, user: promoter)
          end
        end
        let!(:admin_candidacies) do
          create_list(:candidacy, 3, organization:, author: admin)
        end

        context "when candidacy authors" do
          let(:user) { author }

          it "includes user candidacies" do
            expect(subject).to include(*author_candidacies)
          end

          it "does not include admin candidacies" do
            expect(subject).not_to include(*admin_candidacies)
          end
        end

        context "when candidacy promoters" do
          let(:user) { promoter }

          it "includes promoter candidacies" do
            expect(subject).to include(*promoter_candidacies)
          end

          it "does not include admin candidacies" do
            expect(subject).not_to include(*admin_candidacies)
          end
        end

        context "when administrator users" do
          let(:user) { admin }

          it "includes admin candidacies" do
            expect(subject).to include(*admin_candidacies)
          end

          it "includes user candidacies" do
            expect(subject).to include(*author_candidacies)
          end

          it "includes promoter candidacies" do
            expect(subject).to include(*promoter_candidacies)
          end
        end
      end
    end
  end
end
