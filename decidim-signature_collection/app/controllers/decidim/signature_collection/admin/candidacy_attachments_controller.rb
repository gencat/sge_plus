# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # Controller that allows managing all the attachments for an candidacy
      class CandidacyAttachmentsController < Decidim::SignatureCollection::Admin::ApplicationController
        include CandidacyAdmin
        include Decidim::Admin::Concerns::HasAttachments

        add_breadcrumb_item_from_menu :admin_candidacy_menu

        def after_destroy_path
          candidacy_attachments_path(current_candidacy)
        end

        def attached_to
          current_candidacy
        end
      end
    end
  end
end
