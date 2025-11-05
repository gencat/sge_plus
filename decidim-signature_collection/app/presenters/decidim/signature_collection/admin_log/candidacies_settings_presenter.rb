# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module AdminLog
      # This class holds the logic to present a `Decidim::SignatureCollection::CandidaciesSettings`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you should not need to call this class
      # directly, but here is an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    CandidaciesSettingsPresenter.new(action_log, view_helpers).present
      class CandidaciesSettingsPresenter < Decidim::Log::BasePresenter
        private

        def action_string
          case action
          when "update"
            "decidim.signature_collection.admin_log.candidacies_settings.#{action}"
          end
        end
      end
    end
  end
end
