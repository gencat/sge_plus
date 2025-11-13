# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A form object used to collect the all the candidacy type attributes.
      class CandidacyTypeForm < Decidim::Form
        DEFAULT_MINIMUM_COMMITTEE_MEMBERS = 0

        include TranslatableAttributes

        mimic :candidacies_type

        translatable_attribute :title, String
        translatable_attribute :description, Decidim::Attributes::RichText
        attribute :signature_type, String
        attribute :undo_online_signatures_enabled, Boolean
        attribute :attachments_enabled, Boolean
        attribute :comments_enabled, Boolean
        attribute :child_scope_threshold_enabled, Boolean
        attribute :only_global_scope_enabled, Boolean
        attribute :collect_user_extra_fields, Boolean
        translatable_attribute :extra_fields_legal_information, Decidim::Attributes::RichText
        attribute :validate_sms_code_on_votes, Boolean
        attribute :document_number_authorization_handler, String
        attribute :signature_period_start, Decidim::Attributes::TimeWithZone
        attribute :signature_period_end, Decidim::Attributes::TimeWithZone
        attribute :published, Boolean, default: false
        attribute :minimum_signing_age, Integer

        validates :title, :description, translatable_presence: true
        validates :attachments_enabled, :undo_online_signatures_enabled, inclusion: { in: [true, false] }
        validates :minimum_committee_members, numericality: { only_integer: true }, allow_nil: true
        validates :document_number_authorization_handler, presence: true, if: ->(form) { form.collect_user_extra_fields? }

        validates :signature_period_start,
                  comparison: { less_than: :signature_period_end, message: I18n.t("activemodel.attributes.candidacies_type.signature_period_start_less_than") },
                  if: ->(form) { form.signature_period_end.present? && form.signature_period_start.present? }

        validates :signature_period_end,
                  comparison: { greater_than: :signature_period_start, message: I18n.t("activemodel.attributes.candidacies_type.signature_period_end_greater_than") },
                  if: ->(form) { form.signature_period_start.present? && form.signature_period_end.present? }
        validates :minimum_signing_age, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

        alias organization current_organization

        def minimum_committee_members=(value)
          super(value.presence)
        end

        def minimum_committee_members
          DEFAULT_MINIMUM_COMMITTEE_MEMBERS
        end

        def signature_type_options
          Candidacy.signature_types.keys.map do |type|
            [
              I18n.t(
                type,
                scope: %w(activemodel attributes candidacy signature_type_values)
              ), type
            ]
          end
        end
      end
    end
  end
end
