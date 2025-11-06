# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # The main admin application controller for candidacies
      class ApplicationController < Decidim::Admin::ApplicationController
        helper Decidim::SignatureCollection::ScopesHelper

        layout "decidim/admin/candidacies"

        register_permissions(::Decidim::SignatureCollection::Admin::ApplicationController,
                             ::Decidim::SignatureCollection::Permissions,
                             ::Decidim::Admin::Permissions)

        def permissions_context
          super.merge(
            current_participatory_space: try(:current_participatory_space)
          )
        end

        def permission_class_chain
          ::Decidim.permissions_registry.chain_for(::Decidim::SignatureCollection::Admin::ApplicationController)
        end
      end
    end
  end
end
