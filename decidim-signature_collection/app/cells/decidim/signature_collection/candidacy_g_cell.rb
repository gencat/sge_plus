# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # This cell renders the Grid (:g) candidacy card
    # for a given instance of an Candidacy
    class CandidacyGCell < Decidim::CardGCell
      private

      def resource_path
        Decidim::SignatureCollection::Engine.routes.url_helpers.candidacy_path(model)
      end

      def image
        @image ||= model.attachments.find(&:image?)
      end

      def resource_image_url
        return if image.blank?

        image.url
      end

      def metadata_cell
        "decidim/signature_collection/candidacy_metadata_g"
      end
    end
  end
end
