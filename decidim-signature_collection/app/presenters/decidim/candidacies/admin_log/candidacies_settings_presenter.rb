# frozen_string_literal: true

module Decidim
  module Candidacies
    module AdminLog
      # This class holds the logic to present a `Decidim::CandidacysSettings`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you should not need to call this class
      # directly, but here is an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    CandidacysSettingsPresenter.new(action_log, view_helpers).present
      class CandidacysSettingsPresenter < Decidim::Log::BasePresenter
        private

        def action_string
          case action
          when "update"
            "decidim.candidacies.admin_log.candidacies_settings.#{action}"
          end
        end
      end
    end
  end
end
