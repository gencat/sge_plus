# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # The main application controller for candidacies
    #
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    class ApplicationController < Decidim::ApplicationController
      include NeedsPermission
      register_permissions(::Decidim::SignatureCollection::ApplicationController,
                           ::Decidim::SignatureCollection::Permissions,
                           ::Decidim::Admin::Permissions,
                           ::Decidim::Permissions)

      before_action do
        if Decidim::SignatureCollection::CandidaciesType.joins(:scopes).where(organization: current_organization).none?
          flash[:alert] = t("index.uninitialized", scope: "decidim.candidacies")
          redirect_to(decidim.root_path)
        end
      end

      def permissions_context
        super.merge(
          current_participatory_space: try(:current_participatory_space)
        )
      end

      def permission_class_chain
        ::Decidim.permissions_registry.chain_for(::Decidim::SignatureCollection::ApplicationController)
      end

      def permission_scope
        :public
      end
    end
  end
end
