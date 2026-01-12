# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A command with all the business logic that updates an
      # existing candidacy type.
      class UpdateCandidacyType < Decidim::Commands::UpdateResource
        fetch_form_attributes :title, :description, :signature_type, :attachments_enabled, :comments_enabled,
                              :undo_online_signatures_enabled, :collect_user_extra_fields, :minimum_signing_age,
                              :extra_fields_legal_information, :elections,
                              :document_number_authorization_handler, :child_scope_threshold_enabled,
                              :only_global_scope_enabled, :signature_period_start, :signature_period_end, :published

        protected

        def run_after_hooks
          resource.candidacies.signature_type_updatable.each do |candidacy|
            candidacy.update!(signature_type: resource.signature_type)
          end
        end
      end
    end
  end
end
