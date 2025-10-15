# frozen_string_literal: true

module Decidim
  module Candidacies
    # Helper methods for the create candidacy wizard.
    module SignatureTypeOptionsHelper
      def signature_type_options(candidacy_form)
        return all_signature_type_options unless candidacy_form.signature_type_updatable?

        type = ::Decidim::CandidacysType.find(candidacy_form.type_id)
        allowed_signatures = type.allowed_signature_types_for_candidacies

        case allowed_signatures
        when %w(online)
          online_signature_type_options
        when %w(offline)
          offline_signature_type_options
        else
          all_signature_type_options
        end
      end

      private

      def online_signature_type_options
        [
          [
            I18n.t(
              "online",
              scope: "activemodel.attributes.candidacy.signature_type_values"
            ), "online"
          ]
        ]
      end

      def offline_signature_type_options
        [
          [
            I18n.t(
              "offline",
              scope: "activemodel.attributes.candidacy.signature_type_values"
            ), "offline"
          ]
        ]
      end

      def all_signature_type_options
        Candidacy.signature_types.keys.map do |type|
          [
            I18n.t(
              type,
              scope: "activemodel.attributes.candidacy.signature_type_values"
            ), type
          ]
        end
      end
    end
  end
end
