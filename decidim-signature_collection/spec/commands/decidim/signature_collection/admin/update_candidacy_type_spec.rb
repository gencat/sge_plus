# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    module Admin
      describe UpdateCandidacyType, skip: "Awaiting review" do

        let(:form_klass) { CandidacyTypeForm }

        context "when valid data" do
          it_behaves_like "update an candidacy type", true
        end

        context "when validation error" do
          let(:organization) { create(:organization) }
          let(:user) { create(:user, organization:) }
          let!(:candidacy_type) { create(:candidacies_type, organization:, banner_image:) }
          let(:banner_image) { upload_test_file(Decidim::Dev.test_file("city2.jpeg", "image/jpeg")) }
          let(:form) do
            form_klass
              .from_model(candidacy_type)
              .with_context(current_organization: organization)
          end

          let(:command) { described_class.new(form, candidacy_type) }

          it "broadcasts invalid" do
            expect(candidacy_type).to receive(:valid?)
              .at_least(:once)
              .and_return(false)
            expect { command.call }.to broadcast :invalid
          end
        end
      end
    end
  end
end
