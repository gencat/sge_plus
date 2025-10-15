# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # A command with all the business logic that creates a new candidacy type
      class CreateCandidacyType < Decidim::Commands::CreateResource
        fetch_form_attributes :title, :description, :signature_type, :comments_enabled, :attachments_enabled,
                              :undo_online_signatures_enabled, :collect_user_extra_fields, :extra_fields_legal_information,
                              :validate_sms_code_on_votes, :document_number_authorization_handler, :child_scope_threshold_enabled,
                              :only_global_scope_enabled, :organization, :signature_period_start, :signature_period_end

        protected

        def resource_class = Decidim::CandidacysType
      end
    end
  end
end
