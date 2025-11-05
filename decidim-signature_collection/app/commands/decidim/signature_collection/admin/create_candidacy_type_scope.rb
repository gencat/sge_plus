# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A command with all the business logic that creates a new candidacy type scope
      class CreateCandidacyTypeScope < Decidim::Commands::CreateResource
        protected

        fetch_form_attributes :supports_required, :decidim_scopes_id

        def attributes = super.merge(decidim_signature_collection_candidacies_type_id: form.context.type_id)

        def resource_class = Decidim::SignatureCollection::CandidaciesTypeScope
      end
    end
  end
end
