# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # This module's job is to extend the API with custom fields related to
    # decidim-signature_collection.
    module QueryExtensions
      # Public: Extends a type with `decidim-candidacies`'s fields.
      #
      # type - A GraphQL::BaseType to extend.
      #
      # Returns nothing.
      def self.included(type)
        type.field :candidacies_types, [CandidacyApiType], null: false do
          description "Lists all candidacy types"
        end

        type.field :candidacies_type, CandidacyApiType, null: true, description: "Finds an candidacy type" do
          argument :id, GraphQL::Types::ID, "The ID of the candidacy type", required: true
        end

        type.field :candidacies,
                   [Decidim::SignatureCollection::CandidacyType],
                   null: true,
                   description: "Lists all candidacies" do
          argument :filter, Decidim::ParticipatoryProcesses::ParticipatoryProcessInputFilter, "This argument lets you filter the results", required: false
          argument :order, Decidim::ParticipatoryProcesses::ParticipatoryProcessInputSort, "This argument lets you order the results", required: false
        end

        type.field :candidacy,
                   Decidim::SignatureCollection::CandidacyType,
                   null: true,
                   description: "Finds an candidacy" do
          argument :id, GraphQL::Types::ID, "The ID of the participatory space", required: false
        end
      end

      def candidacies_types
        Decidim::SignatureCollection::CandidaciesType.where(
          organization: context[:current_organization]
        )
      end

      def candidacies_type(id:)
        Decidim::SignatureCollection::CandidaciesType.find_by(
          organization: context[:current_organization],
          id:
        )
      end

      def candidacies(filter: {}, order: {})
        manifest = Decidim.participatory_space_manifests.select { |m| m.name == :candidacies }.first
        Decidim::Core::ParticipatorySpaceListBase.new(manifest:).call(object, { filter:, order: }, context)
      end

      def candidacy(id: nil)
        manifest = Decidim.participatory_space_manifests.select { |m| m.name == :candidacies }.first

        Decidim::Core::ParticipatorySpaceFinderBase.new(manifest:).call(object, { id: }, context)
      end
    end
  end
end
