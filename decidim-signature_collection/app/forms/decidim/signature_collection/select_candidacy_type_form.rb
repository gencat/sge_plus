# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # A form object used to collect the candidacy type for an candidacy.
    class SelectCandidacyTypeForm < Form
      mimic :candidacy

      attribute :type_id, Integer

      validates :type_id, presence: true
    end
  end
end
