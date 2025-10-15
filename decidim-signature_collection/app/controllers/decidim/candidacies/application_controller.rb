# frozen_string_literal: true

module Decidim
  module Candidacies
    # The main application controller for candidacies
    #
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    class ApplicationController < Decidim::ApplicationController
      include NeedsPermission
      register_permissions(::Decidim::Candidacies::ApplicationController,
                           ::Decidim::Candidacies::Permissions,
                           ::Decidim::Admin::Permissions,
                           ::Decidim::Permissions)

      before_action do
        if Decidim::CandidacysType.joins(:scopes).where(organization: current_organization).none?
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
        ::Decidim.permissions_registry.chain_for(::Decidim::Candidacies::ApplicationController)
      end

      def permission_scope
        :public
      end
    end
  end
end
