# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module AdminLog
      # This class holds the logic to present a `Decidim::SignatureCollection::CandidaciesType`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you should not need to call this class
      # directly, but here is an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    CandidaciesTypePresenter.new(action_log, view_helpers).present
      class CandidaciesTypePresenter < Decidim::Log::BasePresenter
        private

        def action_string
          case action
          when "create", "update", "delete"
            "decidim.signature_collection.admin_log.candidacies_type.#{action}"
          else
            super
          end
        end

        def diff_fields_mapping
          {
            description: :i18n,
            title: :i18n,
            extra_fields_legal_information: :i18n,
            minimum_committee_members: :integer,
            document_number_authorization_handler: :i18n,
            undo_online_signatures_enabled: :boolean,
            promoting_committee_enabled: :boolean
          }
        end

        def diff_actions
          super + %w(update)
        end
      end
    end
  end
end
