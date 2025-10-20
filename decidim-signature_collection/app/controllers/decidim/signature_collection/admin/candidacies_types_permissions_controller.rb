# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # Controller that allows managing candidacies types
      # permissions in the admin panel.
      class CandidaciesTypesPermissionsController < Decidim::Admin::ResourcePermissionsController
        include Decidim::TranslatableAttributes

        before_action :set_controller_breadcrumb
        add_breadcrumb_item_from_menu :admin_candidacies_menu

        layout "decidim/admin/signature_collection/candidacies"

        register_permissions(::Decidim::SignatureCollection::Admin::CandidaciesTypesPermissionsController,
                             ::Decidim::SignatureCollection::Permissions,
                             ::Decidim::Admin::Permissions)

        def permission_class_chain
          ::Decidim.permissions_registry.chain_for(::Decidim::SignatureCollection::Admin::CandidaciesTypesPermissionsController)
        end

        private

        def set_controller_breadcrumb
          controller_breadcrumb_items.append(
            {
              label: translated_attribute(resource.title),
              url: edit_candidacies_type_path(resource),
              active: false
            },
            {
              label: t("permissions", scope: "decidim.admin.actions"),
              active: true
            }
          )
        end
      end
    end
  end
end
