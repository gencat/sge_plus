# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    module Admin
      describe CreateCandidacyTypeScope do
        let(:form_klass) { CandidacyTypeScopeForm }

        describe "Successfull creation" do
          it_behaves_like "create an candidacy type scope"
        end

        describe "Attempt of creating duplicated typed scopes" do
          let(:organization) { create(:organization) }
          let(:candidacy_type) { create(:candidacies_type, organization:) }
          let!(:candidacy_type_scope) do
            create(:candidacies_type_scope, type: candidacy_type)
          end
          let(:form) do
            form_klass
              .from_model(candidacy_type_scope)
              .with_context(type_id: candidacy_type.id, current_organization: organization)
          end
          let(:command) { described_class.new(form) }

          it "broadcasts invalid" do
            expect { command.call }.to broadcast :invalid
          end
        end
      end
    end
  end
end
