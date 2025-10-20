# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # Controller that allows managing candidacies
      # permissions in the admin panel.
      class CandidaciesPermissionsController < Decidim::Admin::ResourcePermissionsController
        include Decidim::SignatureCollection::NeedsCandidacy
        include Decidim::Admin::ParticipatorySpaceAdminBreadcrumb

        add_breadcrumb_item_from_menu :admin_candidacy_actions_menu

        layout "decidim/admin/signature_collection/candidacies"

        register_permissions(::Decidim::SignatureCollection::Admin::CandidaciesPermissionsController,
                             ::Decidim::SignatureCollection::Permissions,
                             ::Decidim::Admin::Permissions)

        def resource
          current_candidacy
        end

        def permission_class_chain
          ::Decidim.permissions_registry.chain_for(::Decidim::SignatureCollection::Admin::CandidaciesPermissionsController)
        end
      end
    end
  end
end
