# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe CandidaciesTypeScopesController do
      routes { Decidim::SignatureCollection::Engine.routes }

      let(:organization) { create(:organization) }
      let(:candidacy_type) do
        type = create(:candidacies_type, organization:)

        3.times do
          CandidaciesTypeScope.create(
            type:,
            scope: create(:scope, organization:),
            supports_required: 1000
          )
        end

        type
      end

      let(:other_candidacy_type) do
        type = create(:candidacies_type, organization:)

        3.times do
          CandidaciesTypeScope.create(
            type:,
            scope: create(:scope, organization:),
            supports_required: 1000
          )
        end

        type
      end

      describe "GET search" do
        before do
          request.env["decidim.current_organization"] = organization
        end

        it "Returns only scoped types for the given type" do
          expect(other_candidacy_type.scopes).not_to be_empty

          get :search, params: { type_id: candidacy_type.id }

          expect(subject.helpers.scoped_types).to include(*candidacy_type.scopes)
          expect(subject.helpers.scoped_types).not_to include(*other_candidacy_type.scopes)
        end
      end
    end
  end
end
