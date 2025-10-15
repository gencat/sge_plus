# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Candidacies
    describe VersionsController, versioning: true do
      routes { Decidim::Candidacies::Engine.routes }

      let(:resource) { create(:candidacy) }

      it_behaves_like "versions controller"
    end
  end
end
