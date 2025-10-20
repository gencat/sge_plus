# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Candidacy type.
    class CandidaciesType < ApplicationRecord
      include Decidim::HasResourcePermission
      include Decidim::TranslatableResource
      include Decidim::HasUploadValidations
      include Decidim::Traceable

      translatable_fields :title, :description, :extra_fields_legal_information

      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"

      has_many :scopes,
               foreign_key: "decidim_signature_collection_candidacies_type_id",
               class_name: "Decidim::SignatureCollection::CandidaciesTypeScope",
               dependent: :destroy,
               inverse_of: :type

      has_many :candidacies,
               through: :scopes,
               class_name: "Decidim::SignatureCollection::Candidacy"

      enum signature_type: [:online, :offline, :any], _suffix: true

      validates :title, :description, :signature_type, presence: true
      validates :document_number_authorization_handler, presence: true, if: ->(form) { form.collect_user_extra_fields? }

      has_one_attached :banner_image
      validates_upload :banner_image, uploader: Decidim::BannerImageUploader

      scope :published, -> { where(published: true) }

      def allowed_signature_types_for_candidacies
        return %w(online offline any) if any_signature_type?

        Array(signature_type.to_s)
      end

      def allow_resource_permissions?
        true
      end

      def mounted_admin_engine
        "decidim_admin_candidacies"
      end

      def mounted_params
        { host: organization.host }
      end

      def self.log_presenter_class_for(_log)
        Decidim::SignatureCollection::AdminLog::CandidaciesTypePresenter
      end

      def signature_period_configured?
        signature_period_start.present? || signature_period_end.present?
      end
    end
  end
end
