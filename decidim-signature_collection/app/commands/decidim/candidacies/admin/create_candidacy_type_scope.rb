# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # A command with all the business logic that creates a new candidacy type scope
      class CreateCandidacyTypeScope < Decidim::Commands::CreateResource
        protected

        fetch_form_attributes :supports_required, :decidim_scopes_id

        def attributes = super.merge(decidim_candidacies_types_id: form.context.type_id)

        def resource_class = Decidim::CandidacysTypeScope
      end
    end
  end
end
