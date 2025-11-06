# frozen_string_literal: true

module Decidim
  module SignatureCollection
    class Permissions < Decidim::DefaultPermissions
      def permissions
        # Delegate the admin permission checks to the admin permissions class
        return Decidim::SignatureCollection::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin

        return permission_action if candidacy && !candidacy.is_a?(Decidim::SignatureCollection::Candidacy)
        return permission_action if permission_action.scope != :public

        # Non-logged users permissions
        list_public_candidacies?
        read_public_candidacy?
        search_candidacy_types_and_scopes?
        request_membership?

        return permission_action unless user

        create_candidacy?
        edit_public_candidacy?
        update_public_candidacy?
        print_candidacy?

        vote_candidacy?
        sign_candidacy?
        unvote_candidacy?

        candidacy_attachment?

        candidacy_committee_action?
        send_to_technical_validation?

        permission_action
      end

      private

      def candidacy
        @candidacy ||= context.fetch(:candidacy, nil) || context.fetch(:current_participatory_space, nil)
      end

      def candidacy_type
        @candidacy_type ||= context[:candidacy_type]
      end

      def list_public_candidacies?
        allow! if permission_action.subject == :candidacy &&
                  permission_action.action == :list
      end

      def read_public_candidacy?
        return false unless [:candidacy, :participatory_space].include?(permission_action.subject) &&
                            permission_action.action == :read

        return allow! if candidacy.open? || candidacy.rejected? || candidacy.accepted?
        return allow! if user_can_preview_space?
        return allow! if user && authorship_or_admin?

        disallow!
      end

      def search_candidacy_types_and_scopes?
        return false unless permission_action.action == :search
        return false unless [:candidacy_type, :candidacy_type_scope, :candidacy_type_signature_types].include?(permission_action.subject)

        allow!
      end

      def create_candidacy?
        return false unless permission_action.subject == :candidacy &&
                            permission_action.action == :create

        toggle_allow(creation_enabled?)
      end

      def edit_public_candidacy?
        return false unless permission_action.subject == :candidacy &&
                            permission_action.action == :edit

        toggle_allow(candidacy&.created? && authorship_or_admin?)
      end

      def update_public_candidacy?
        return false unless permission_action.subject == :candidacy &&
                            permission_action.action == :update

        toggle_allow(candidacy&.created? && authorship_or_admin?)
      end

      def request_membership?
        return false unless permission_action.subject == :candidacy &&
                            permission_action.action == :request_membership

        toggle_allow(can_request_membership?)
      end

      def can_request_membership?
        return access_request_without_user? if user.blank?

        access_request_membership?
      end

      def access_request_without_user?
        (!candidacy.open? && candidacy.promoting_committee_enabled?) || Decidim::SignatureCollection.do_not_require_authorization
      end

      def access_request_membership?
        !candidacy.open? &&
          candidacy.promoting_committee_enabled? &&
          !candidacy.has_authorship?(user) &&
          (
          Decidim::SignatureCollection.do_not_require_authorization ||
              UserAuthorizations.for(user).any? ||
              Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?
        )
      end

      def print_candidacy?
        return false unless permission_action.action == :print &&
                            permission_action.subject == :candidacy

        toggle_allow(Decidim::SignatureCollection.print_enabled && (authorship_or_admin? || committee_member?))
      end

      def committee_member?
        CandidaciesPromoted.by(user).exists?(id: candidacy.id)
      end

      def vote_candidacy?
        return false unless permission_action.action == :vote &&
                            permission_action.subject == :candidacy

        toggle_allow(can_vote?)
      end

      def authorized?(permission_action, resource: nil, permissions_holder: nil)
        return false unless resource || permissions_holder

        ActionAuthorizer.new(user, permission_action, permissions_holder, resource).authorize.ok?
      end

      def unvote_candidacy?
        return false unless permission_action.action == :unvote &&
                            permission_action.subject == :candidacy

        can_unvote = candidacy.accepts_online_unvotes? &&
                     candidacy.organization&.id == user.organization&.id &&
                     candidacy.votes.where(author: user).any?

        toggle_allow(can_unvote)
      end

      def candidacy_attachment?
        return false unless permission_action.action == :add_attachment &&
                            permission_action.subject == :candidacy

        toggle_allow(candidacy_type.attachments_enabled?)
      end

      def sign_candidacy?
        return false unless permission_action.action == :sign_candidacy &&
                            permission_action.subject == :candidacy

        can_sign = can_vote? &&
                   context.fetch(:signature_has_steps, false)

        toggle_allow(can_sign)
      end

      def decidim_user_group_id
        context.fetch(:group_id, nil)
      end

      def can_vote?
        candidacy.votes_enabled? &&
          candidacy.organization&.id == user.organization&.id &&
          candidacy.votes.where(author: user).empty?
      end

      def can_user_support?(candidacy)
        !candidacy.offline_signature_type? && (
        Decidim::SignatureCollection.do_not_require_authorization ||
            UserAuthorizations.for(user).any?
      )
      end

      def user_can_preview_space?
        context[:share_token].present? && Decidim::ShareToken.use!(token_for: candidacy, token: context[:share_token], user:)
      rescue ActiveRecord::RecordNotFound, StandardError
        nil
      end

      def candidacy_committee_action?
        return false unless permission_action.subject == :candidacy_committee_member

        request = context.fetch(:request, nil)
        return false unless user.admin? || candidacy&.has_authorship?(user)

        case permission_action.action
        when :index
          allow!
        when :approve
          toggle_allow(!request&.accepted?)
        when :revoke
          toggle_allow(!request&.rejected?)
        end
      end

      def send_to_technical_validation?
        return false unless permission_action.action == :send_to_technical_validation &&
                            permission_action.subject == :candidacy

        toggle_allow(allowed_to_send_to_technical_validation?)
      end

      def allowed_to_send_to_technical_validation?
        candidacy.created? && (
        !candidacy.created_by_individual? ||
            candidacy.enough_committee_members?
      )
      end

      def authorship_or_admin?
        candidacy&.has_authorship?(user) || user.admin?
      end
    end
  end
end
