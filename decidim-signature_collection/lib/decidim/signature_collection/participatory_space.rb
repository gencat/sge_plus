# frozen_string_literal: true

Decidim.register_participatory_space(:candidacies) do |participatory_space|
  participatory_space.icon = "media/images/decidim_candidacies.svg"
  participatory_space.stylesheet = "decidim/signature_collection"

  participatory_space.context(:public) do |context|
    context.engine = Decidim::SignatureCollection::Engine
    context.layout = "layouts/decidim/candidacy"
  end

  participatory_space.context(:admin) do |context|
    context.engine = Decidim::SignatureCollection::AdminEngine
    context.layout = "layouts/decidim/admin/candidacy"
  end

  participatory_space.participatory_spaces do |organization|
    Decidim::SignatureCollection::Candidacy.where(organization:)
  end

  participatory_space.query_type = "Decidim::SignatureCollection::CandidacyType"

  participatory_space.breadcrumb_cell = "decidim/signature_collection/candidacy_dropdown_metadata"

  participatory_space.register_resource(:candidacy) do |resource|
    resource.actions = %w(comment)
    resource.permissions_class_name = "Decidim::SignatureCollection::Permissions"
    resource.model_class_name = "Decidim::SignatureCollection::Candidacy"
    resource.card = "decidim/signature_collection/candidacy"
    resource.searchable = true
  end

  participatory_space.register_resource(:candidacies_type) do |resource|
    resource.model_class_name = "Decidim::SignatureCollection::CandidaciesType"
    resource.actions = %w(vote create)
  end

  participatory_space.model_class_name = "Decidim::SignatureCollection::Candidacy"
  participatory_space.permissions_class_name = "Decidim::SignatureCollection::Permissions"

  participatory_space.data_portable_entities = [
    "Decidim::SignatureCollection::Candidacy"
  ]

  participatory_space.exports :candidacies do |export|
    export.collection do
      Decidim::SignatureCollection::Candidacy.public_spaces
    end

    export.include_in_open_data = true

    export.serializer Decidim::SignatureCollection::CandidacySerializer
    export.open_data_serializer Decidim::SignatureCollection::OpenDataCandidacySerializer
  end

  participatory_space.seeds do
    require "decidim/signature_collection/seeds"

    Decidim::SignatureCollection::Seeds.new.call
  end
end
