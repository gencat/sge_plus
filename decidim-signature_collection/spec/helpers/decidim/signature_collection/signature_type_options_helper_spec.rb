# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe SignatureTypeOptionsHelper do
      let(:online) { %w(Online online) }
      let(:offline) { ["In-person", "offline"] }
      let(:mixed) { %w(Mixed any) }
      let(:all) { [online, offline, mixed] }

      let(:organization) { create(:organization) }
      let(:candidacy_type) { create(:candidacies_type, signature_type:, organization:) }
      let(:scope) { create(:candidacies_type_scope, type: candidacy_type) }
      let(:candidacy_state) { "created" }
      let(:candidacy) { create(:candidacy, organization:, scoped_type: scope, signature_type:, state: candidacy_state) }

      let(:form_klass) { ::Decidim::SignatureCollection::Admin::CandidacyForm }
      let(:form) do
        form_klass.from_params(
          form_params
        ).with_context(
          current_organization: organization,
          candidacy:
        )
      end
      let(:form_params) do
        {
          type_id: candidacy_type.id,
          decidim_scope_id: scope.id,
          state: candidacy_state
        }
      end
      let(:options) do
        helper.signature_type_options(form)
      end

      context "when any signature enabled" do
        let(:signature_type) { "any" }

        it "contains online and offline signature type options" do
          expect(options).to match_array(all)
        end
      end

      context "when online signature disabled" do
        let(:signature_type) { "offline" }

        it "contains offline signature type options" do
          expect(options).not_to include(online)
          expect(options).not_to include(mixed)
          expect(options).to include(offline)
        end
      end

      context "when online signature enabled" do
        let(:signature_type) { "online" }

        it "contains all signature type options" do
          expect(options).to include(online)
          expect(options).not_to include(mixed)
          expect(options).not_to include(offline)
        end
      end
    end
  end
end
