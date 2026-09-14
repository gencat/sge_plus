# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # This cell renders the Grid (:g) candidacy card
    # for a given instance of an Candidacy
    class CandidacyGCell < Decidim::CardGCell
      private

      def resource_path
        if resource.state == "created" || resource.state == "validating"
          Decidim::SignatureCollection::Engine.routes.url_helpers.load_candidacy_draft_create_candidacy_index_path(candidacy_id: resource.id)
        else
          Decidim::SignatureCollection::Engine.routes.url_helpers.candidacy_path(model)
        end
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
