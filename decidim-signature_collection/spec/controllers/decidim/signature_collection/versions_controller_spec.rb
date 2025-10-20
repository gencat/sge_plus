# frozen_string_literal: true

require "spec_helper"

module Decidim
  module SignatureCollection
    describe VersionsController, versioning: true do
      routes { Decidim::SignatureCollection::Engine.routes }

      let(:resource) { create(:candidacy) }

      it_behaves_like "versions controller"
    end
  end
end
