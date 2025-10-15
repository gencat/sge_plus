# frozen_string_literal: true

module Decidim
  module Candidacies
    # This interface represents a commentable object.

    module CandidacyTypeInterface
      include Decidim::Api::Types::BaseInterface
      description "An interface that can be used in Candidacy objects."

      field :candidacy_type, Decidim::Candidacies::CandidacyApiType, "The object's candidacy type", null: true, method: :type
    end
  end
end
