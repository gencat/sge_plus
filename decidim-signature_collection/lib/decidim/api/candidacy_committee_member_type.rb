# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # This type represents an candidacy committee member.
    class CandidacyCommitteeMemberType < Decidim::Api::Types::BaseObject
      implements Decidim::Core::TimestampsInterface

      graphql_name "CandidacyCommitteeMemberType"
      description "An candidacy committee member"

      field :id, GraphQL::Types::ID, "Internal ID for this member of the committee", null: false
      field :state, GraphQL::Types::String, "Type of the committee member", null: true
      field :user, Decidim::Core::UserType, "The decidim user for this candidacy committee member", null: true
    end
  end
end
