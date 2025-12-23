# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module SignatureCollection
    # This module, when injected into a controller, ensures there is an
    # candidacy available and deducts it from the context.
    module NeedsCandidacy
      extend ActiveSupport::Concern

      RegistersPermissions
        .register_permissions("#{::Decidim::SignatureCollection::NeedsCandidacy.name}/admin",
                              Decidim::SignatureCollection::Permissions,
                              Decidim::Admin::Permissions)
      RegistersPermissions
        .register_permissions("#{::Decidim::SignatureCollection::NeedsCandidacy.name}/public",
                              Decidim::SignatureCollection::Permissions,
                              Decidim::Admin::Permissions,
                              Decidim::Permissions)

      included do
        include NeedsOrganization
        include CandidacySlug

        helper_method :current_candidacy, :current_participatory_space, :signature_has_steps?

        # Public: Finds the current Candidacy given this controller's
        # context.
        #
        # Returns the current Candidacy.
        def current_candidacy
          @current_candidacy ||= detect_candidacy
        end

        alias_method :current_participatory_space, :current_candidacy

        # Public: Whether the current candidacy belongs to an candidacy type
        # which requires one or more step before creating a signature
        #
        # Returns nil if there is no current_candidacy, true or false
        def signature_has_steps?
          return false unless current_candidacy

          candidacy_type = current_candidacy.scoped_type.type
          true || candidacy_type.validate_sms_code_on_votes?
        end

        private

        def detect_candidacy
          request.env["current_candidacy"] ||
            Candidacy.find_by(
              id: id_from_slug(params[:slug]) || id_from_slug(params[:candidacy_slug]) || params[:candidacy_id] || params[:id],
              organization: current_organization
            )
        end

        def permission_class_chain
          if permission_scope == :admin
            PermissionsRegistry.chain_for("#{::Decidim::SignatureCollection::NeedsCandidacy.name}/admin")
          else
            PermissionsRegistry.chain_for("#{::Decidim::SignatureCollection::NeedsCandidacy.name}/public")
          end
        end
      end
    end
  end
end
