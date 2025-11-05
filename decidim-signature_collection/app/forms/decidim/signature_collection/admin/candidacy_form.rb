# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A form object used to show the candidacy data in the administration
      # panel.
      class CandidacyForm < Form
        include TranslatableAttributes

        mimic :candidacy

        translatable_attribute :title, String
        translatable_attribute :description, Decidim::Attributes::RichText
        attribute :type_id, Integer
        attribute :decidim_scope_id, Integer
        attribute :area_id, Integer
        attribute :signature_type, String
        attribute :signature_start_date, Decidim::Attributes::LocalizedDate
        attribute :signature_end_date, Decidim::Attributes::LocalizedDate
        attribute :hashtag, String
        attribute :offline_votes, Hash
        attribute :state, String
        attribute :attachment, AttachmentForm

        validates :title, :description, translatable_presence: true
        validates :area, presence: true, if: ->(form) { form.area_id.present? }
        validates :signature_type, presence: true, if: :signature_type_updatable?
        validates :signature_start_date, presence: true, if: ->(form) { form.context.candidacy.published? }
        validates :signature_end_date, presence: true, if: ->(form) { form.context.candidacy.published? }
        validates :signature_end_date, date: { after: :signature_start_date }, if: lambda { |form|
          form.signature_start_date.present? && form.signature_end_date.present?
        }
        validates :signature_end_date, date: { after: Date.current }, if: lambda { |form|
          form.signature_start_date.blank? && form.signature_end_date.present?
        }

        validate :notify_missing_attachment_if_errored
        validate :area_is_not_removed

        def map_model(model)
          self.type_id = model.type.id
          self.decidim_scope_id = model.scope&.id
          self.offline_votes = offline_votes.empty? ? zero_offline_votes_with_scopes_names(model) : offline_votes_with_scopes_names(model)
        end

        def signature_type_updatable?
          @signature_type_updatable ||= begin
            state ||= context.candidacy.state
            (state == "validating" && context.current_user.admin?) || state == "created"
          end
        end

        def state_updatable?
          false
        end

        def area_updatable?
          @area_updatable ||= current_user.admin? || context.candidacy.created?
        end

        def scoped_type_id
          return unless type && decidim_scope_id

          type.scopes.find_by(decidim_scopes_id: decidim_scope_id.presence).id
        end

        def area
          @area ||= current_organization.areas.find_by(id: area_id)
        end

        private

        # Private: set the in-person signatures to zero for every scope
        def zero_offline_votes_with_scopes_names(model)
          model.votable_candidacy_type_scopes.each_with_object({}) do |candidacy_scope_type, all_votes|
            all_votes[candidacy_scope_type.decidim_scopes_id || "global"] = [0, candidacy_scope_type.scope_name]
          end
        end

        # Private: set the in-person signatures for every scope
        def offline_votes_with_scopes_names(model)
          model.offline_votes.delete("total")
          model.offline_votes.each_with_object({}) do |(decidim_scope_id, votes), all_votes|
            scope_name = model.votable_candidacy_type_scopes.find do |candidacy_scope_type|
              (candidacy_scope_type.global_scope? && decidim_scope_id == "global") ||
                candidacy_scope_type.decidim_scopes_id == decidim_scope_id.to_i
            end.scope_name

            all_votes[decidim_scope_id || "global"] = [votes, scope_name]
          end
        end

        def type
          @type ||= type_id ? Decidim::SignatureCollection::CandidaciesType.find(type_id) : context.candidacy.type
        end

        # This method will add an error to the `attachment` field only if there is
        # any error in any other field. This is needed because when the form has
        # an error, the attachment is lost, so we need a way to inform the user of
        # this problem.
        def notify_missing_attachment_if_errored
          errors.add(:attachment, :needs_to_be_reattached) if errors.any? && attachment.present?
        end

        def area_is_not_removed
          return if context.candidacy.decidim_area_id.blank? || context.candidacy.created?

          errors.add(:area_id, :blank) if area_id.blank?
        end
      end
    end
  end
end
