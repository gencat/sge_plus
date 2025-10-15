# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    describe CandidacyTypes do
      subject { described_class.new(organization) }

      let!(:organization) { create(:organization) }
      let!(:candidacy_types) { create_list(:candidacies_type, 3, organization:) }

      let!(:other_organization) { create(:organization) }
      let!(:other_candidacy_types) { create_list(:candidacies_type, 3, organization: other_organization) }

      it "Returns only candidacy types for the given organization" do
        expect(subject).to include(*candidacy_types)
        expect(subject).not_to include(*other_candidacy_types)
      end
    end
  end
end
