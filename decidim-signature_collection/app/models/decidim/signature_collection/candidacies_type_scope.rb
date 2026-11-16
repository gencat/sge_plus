# frozen_string_literal: true

module Decidim
  module SignatureCollection
    class CandidaciesTypeScope < ApplicationRecord
      belongs_to :type,
                 foreign_key: "decidim_signature_collection_candidacies_type_id",
                 class_name: "Decidim::SignatureCollection::CandidaciesType",
                 inverse_of: :scopes

      belongs_to :taxonomy,
                 foreign_key: "decidim_taxonomy_id",
                 class_name: "Decidim::Taxonomy",
                 optional: true

      belongs_to :scope,
                 foreign_key: "decidim_scopes_id",
                 class_name: "Decidim::Scope",
                 optional: true

      has_many :candidacies,
               foreign_key: "scoped_type_id",
               class_name: "Decidim::SignatureCollection::Candidacy",
               dependent: :restrict_with_error,
               inverse_of: :scoped_type

      # Type scopes whose candidacy type signature period is currently active.
      # Mirrors Candidacy#signature_period_active? (a period with no start nor end is never active).
      scope :with_active_signature_period, lambda {
        now = Time.current
        types = CandidaciesType.arel_table

        joins(:type)
          .where(types[:signature_period_start].not_eq(nil).or(types[:signature_period_end].not_eq(nil)))
          .where(types[:signature_period_start].eq(nil).or(types[:signature_period_start].lteq(now)))
          .where(types[:signature_period_end].eq(nil).or(types[:signature_period_end].gteq(now)))
      }

      validates :scope, uniqueness: { scope: :type }
      validates :supports_required, presence: true
      validates :supports_required, numericality: {
        only_integer: true,
        greater_than: 0
      }

      def global_scope?
        decidim_scopes_id.nil?
      end

      def scope_name
        return { I18n.locale.to_s => I18n.t("decidim.scopes.global") } if global_scope?

        scope&.name.presence || { I18n.locale.to_s => I18n.t("decidim.signature_collection.unavailable_scope") }
      end

      def taxonomy_name
        taxonomy&.name.presence || { I18n.locale.to_s => I18n.t("decidim.signature_collection.unavailable_scope") }
      end
    end
  end
end
