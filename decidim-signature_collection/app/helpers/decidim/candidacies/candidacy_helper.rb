# frozen_string_literal: true

module Decidim
  module Candidacies
    # Helper method related to candidacy object and its internal state.
    module CandidacyHelper
      include Decidim::SanitizeHelper
      include Decidim::ResourceVersionsHelper

      def metadata_badge_css_class(candidacy)
        case candidacy
        when "accepted", "open"
          "success"
        when "rejected", "discarded"
          "alert"
        when "validating"
          "warning"
        else
          "muted"
        end
      end

      # Public: The state of an candidacy from an administration perspective in
      # a way that a human can understand.
      #
      # state - String
      #
      # Returns a String
      def humanize_admin_state(state)
        I18n.t(state, scope: "decidim.candidacies.admin_states", default: :created)
      end

      def render_committee_tooltip
        with_tooltip t("decidim.candidacies.create_candidacy.share_committee_link.invite_to_committee_help"), class: "left" do
          icon "file-copy-line"
        end
      end

      def hero_background_path(candidacy)
        candidacy.attachments.find(&:image?)&.url
      end
    end
  end
end
