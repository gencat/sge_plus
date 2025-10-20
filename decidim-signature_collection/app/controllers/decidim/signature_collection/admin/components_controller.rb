# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # Controller that allows managing the Candidacy's Components in the
      # admin panel.
      class ComponentsController < Decidim::Admin::ComponentsController
        layout "decidim/admin/signature_collection/candidacy"

        include NeedsCandidacy
        include Decidim::Admin::ParticipatorySpaceAdminBreadcrumb

        add_breadcrumb_item_from_menu :admin_candidacy_menu
      end
    end
  end
end
