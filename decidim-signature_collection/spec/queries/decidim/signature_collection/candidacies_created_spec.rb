# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidaciesCreated do
      let!(:user) { create(:user, :confirmed, organization:) }
      let!(:admin) { create(:user, :confirmed, :admin, organization:) }
      let!(:organization) { create(:organization) }
      let!(:user_candidacies) { create_list(:candidacy, 3, organization:, author: user) }
      let!(:admin_candidacies) { create_list(:candidacy, 3, organization:, author: admin) }

      context "when candidacy authors" do
        subject { described_class.new(user) }

        it "includes only user candidacies" do
          expect(subject).to include(*user_candidacies)
          expect(subject).not_to include(*admin_candidacies)
        end
      end
    end
  end
end
