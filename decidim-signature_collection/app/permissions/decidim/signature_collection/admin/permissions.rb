# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin
          return permission_action unless user

          user_can_enter_space_area?

          return permission_action if candidacy && !candidacy.is_a?(Decidim::SignatureCollection::Candidacy)

          user_can_read_participatory_space?

          if !user.admin? && candidacy&.has_authorship?(user)
            candidacy_committee_action?
            candidacy_user_action?
            attachment_action?
            candidacies_settings_action?

            return permission_action
          end

          if !user.admin? && has_candidacies?
            read_candidacy_list_action?

            return permission_action
          end

          return permission_action unless user.admin?

          candidacy_type_action?
          candidacy_type_scope_action?
          candidacy_committee_action?
          candidacy_admin_user_action?
          candidacy_export_action?
          candidacies_settings_action?
          moderator_action?
          share_tokens_action?
          allow! if permission_action.subject == :attachment

          permission_action
        end

        private

        def candidacy
          @candidacy ||= context.fetch(:candidacy, nil) || context.fetch(:current_participatory_space, nil)
        end

        def user_can_read_participatory_space?
          return false unless permission_action.action == :read &&
                              permission_action.subject == :participatory_space

          toggle_allow(user.admin? || candidacy.has_authorship?(user))
        end

        def user_can_enter_space_area?
          return false unless permission_action.action == :enter &&
                              permission_action.subject == :space_area &&
                              context.fetch(:space_name, nil) == :candidacies

          toggle_allow(user.admin? || has_candidacies?)
        end

        def has_candidacies?
          (CandidaciesCreated.by(user) | CandidaciesPromoted.by(user)).any?
        end

        def attachment_action?
          return false unless permission_action.subject == :attachment

          disallow!
          return false unless candidacy.attachments_enabled?

          attachment = context.fetch(:attachment, nil)
          attached = attachment&.attached_to

          case permission_action.action
          when :update, :destroy
            toggle_allow(attached && attached.is_a?(Decidim::SignatureCollection::Candidacy))
          when :read, :create
            allow!
          else
            disallow!
          end
        end

        def candidacy_type_action?
          return false unless [:candidacy_type, :candidacies_type].include? permission_action.subject

          candidacy_type = context.fetch(:candidacy_type, nil)

          case permission_action.action
          when :destroy
            scopes_are_empty = candidacy_type && candidacy_type.scopes.all? { |scope| scope.candidacies.empty? }
            toggle_allow(scopes_are_empty)
          else
            allow!
          end
        end

        def candidacy_type_scope_action?
          return false unless permission_action.subject == :candidacy_type_scope

          candidacy_type_scope = context.fetch(:candidacy_type_scope, nil)

          case permission_action.action
          when :destroy
            scopes_is_empty = candidacy_type_scope && candidacy_type_scope.candidacies.empty?
            toggle_allow(scopes_is_empty)
          else
            allow!
          end
        end

        def candidacy_committee_action?
          return false unless permission_action.subject == :candidacy_committee_member

          request = context.fetch(:request, nil)

          case permission_action.action
          when :index
            allow!
          when :approve
            toggle_allow(!request&.accepted?)
          when :revoke
            toggle_allow(!request&.rejected?)
          end
        end

        def candidacy_admin_user_action?
          return false unless permission_action.subject == :candidacy

          case permission_action.action
          when :print
            toggle_allow(Decidim::SignatureCollection.print_enabled && user.admin?)
          when :publish, :discard
            toggle_allow(candidacy.validating?)
          when :unpublish
            toggle_allow(candidacy.published?)
          when :export_pdf_signatures, :export_xml_signatures
            toggle_allow(candidacy.published? || candidacy.accepted? || candidacy.rejected?)
          when :export_votes
            toggle_allow(candidacy.offline_signature_type? || candidacy.any_signature_type?)
          when :accept
            allowed = candidacy.published? &&
                      candidacy.type.signature_period_end < Date.current &&
                      candidacy.supports_goal_reached?
            toggle_allow(allowed)
          when :reject
            allowed = candidacy.published? &&
                      candidacy.type.signature_period_end < Date.current &&
                      !candidacy.supports_goal_reached?
            toggle_allow(allowed)
          when :send_to_technical_validation
            toggle_allow(allowed_to_send_to_technical_validation?)
          else
            allow!
          end
        end

        def candidacy_export_action?
          allow! if permission_action.subject == :candidacies && permission_action.action == :export
          allow! if permission_action.action == :export && permission_action.subject == :component_data
        end

        def candidacies_settings_action?
          return false unless permission_action.action == :update &&
                              permission_action.subject == :candidacies_settings

          toggle_allow(user.admin?)
        end

        def moderator_action?
          return false unless permission_action.subject == :moderation

          allow!
        end

        def share_tokens_action?
          return false unless permission_action.subject == :share_tokens

          allow!
        end

        def read_candidacy_list_action?
          return false unless permission_action.subject == :candidacy &&
                              permission_action.action == :list

          allow!
        end

        def candidacy_user_action?
          return false unless permission_action.subject == :candidacy

          case permission_action.action
          when :read
            toggle_allow(Decidim::SignatureCollection.print_enabled)
          when :preview, :edit
            allow!
          when :update
            toggle_allow(candidacy.created?)
          when :send_to_technical_validation
            toggle_allow(allowed_to_send_to_technical_validation?)
          when :manage_membership
            toggle_allow(candidacy.promoting_committee_enabled?)
          else
            disallow!
          end
        end

        def allowed_to_send_to_technical_validation?
          candidacy.discarded? ||
            (candidacy.created? && (
              !candidacy.created_by_individual? ||
              candidacy.enough_committee_members?
            ))
        end
      end
    end
  end
end
