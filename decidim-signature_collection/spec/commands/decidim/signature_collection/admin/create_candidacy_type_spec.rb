# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    module Admin
      describe CreateCandidacyType do
        let(:form_klass) { CandidacyTypeForm }

        describe "successful creation" do
          it_behaves_like "create an candidacy type", true
        end

        describe "Validation failure" do
          let(:organization) { create(:organization) }
          let(:user) { create(:user, organization:) }
          let!(:candidacy_type) do
            build(:candidacies_type, banner_image: nil, organization:)
          end
          let(:form) do
            form_klass
              .from_model(candidacy_type)
              .with_context(current_organization: organization, current_user: user)
          end
          let(:command) { described_class.new(form) }

          it "broadcasts invalid" do
            expect(CandidaciesType).to receive(:new).at_least(:once).and_return(candidacy_type)
            expect(candidacy_type).to receive(:persisted?)
              .at_least(:once)
              .and_return(false)

            expect { command.call }.to broadcast :invalid
          end
        end
      end
    end
  end
end
