# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    module Admin
      describe UpdateCandidacyTypeScope do
        let(:form_klass) { CandidacyTypeScopeForm }

        context "when successful update" do
          it_behaves_like "update an candidacy type scope"
        end
      end
    end
  end
end
