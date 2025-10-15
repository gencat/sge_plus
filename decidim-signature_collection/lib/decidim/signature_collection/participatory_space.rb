# frozen_string_literal: true

Decidim.register_participatory_space(:candidacies) do |participatory_space|
  participatory_space.icon = "media/images/decidim_candidacies.svg"
  participatory_space.stylesheet = "decidim/candidacies/candidacies"

  participatory_space.context(:public) do |context|
    context.engine = Decidim::Candidacies::Engine
    context.layout = "layouts/decidim/candidacy"
  end

  participatory_space.context(:admin) do |context|
    context.engine = Decidim::Candidacies::AdminEngine
    context.layout = "layouts/decidim/admin/candidacy"
  end

  participatory_space.participatory_spaces do |organization|
    Decidim::Candidacy.where(organization:)
  end

  participatory_space.query_type = "Decidim::Candidacies::CandidacyType"

  participatory_space.breadcrumb_cell = "decidim/candidacies/candidacy_dropdown_metadata"

  participatory_space.register_resource(:candidacy) do |resource|
    resource.actions = %w(comment)
    resource.permissions_class_name = "Decidim::Candidacies::Permissions"
    resource.model_class_name = "Decidim::Candidacy"
    resource.card = "decidim/candidacies/candidacy"
    resource.searchable = true
  end

  participatory_space.register_resource(:candidacies_type) do |resource|
    resource.model_class_name = "Decidim::CandidacysType"
    resource.actions = %w(vote create)
  end

  participatory_space.model_class_name = "Decidim::Candidacy"
  participatory_space.permissions_class_name = "Decidim::Candidacies::Permissions"

  participatory_space.data_portable_entities = [
    "Decidim::Candidacy"
  ]

  participatory_space.exports :candidacies do |export|
    export.collection do
      Decidim::Candidacy.public_spaces
    end

    export.include_in_open_data = true

    export.serializer Decidim::Candidacies::CandidacySerializer
    export.open_data_serializer Decidim::Candidacies::OpenDataCandidacySerializer
  end

  participatory_space.seeds do
    require "decidim/candidacies/seeds"

    Decidim::Candidacies::Seeds.new.call
  end
end
