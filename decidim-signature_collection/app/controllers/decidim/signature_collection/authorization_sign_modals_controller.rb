# frozen_string_literal: true

module Decidim
  module SignatureCollection
    class AuthorizationSignModalsController < Decidim::SignatureCollection::ApplicationController
      include Decidim::SignatureCollection::NeedsCandidacy

      helper_method :authorizations, :authorize_action_path
      layout false

      def show
        render template: "decidim/authorization_modals/show"
      end

      def authorize_action_path(handler_name)
        authorizations.status_for(handler_name).current_path(redirect_url: URI(request.referer).path)
      end

      private

      def authorizations
        @authorizations ||= action_authorized_to("vote", resource: current_candidacy, permissions_holder: current_candidacy.type)
      end
    end
  end
end
