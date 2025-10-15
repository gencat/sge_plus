# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # Controller that allows managing candidacies
      # permissions in the admin panel.
      class CandidacysPermissionsController < Decidim::Admin::ResourcePermissionsController
        include Decidim::Candidacies::NeedsCandidacy
        include Decidim::Admin::ParticipatorySpaceAdminBreadcrumb

        add_breadcrumb_item_from_menu :admin_candidacy_actions_menu

        layout "decidim/admin/candidacies"

        register_permissions(::Decidim::Candidacies::Admin::CandidacysPermissionsController,
                             ::Decidim::Candidacies::Permissions,
                             ::Decidim::Admin::Permissions)

        def resource
          current_candidacy
        end

        def permission_class_chain
          ::Decidim.permissions_registry.chain_for(::Decidim::Candidacies::Admin::CandidacysPermissionsController)
        end
      end
    end
  end
end
