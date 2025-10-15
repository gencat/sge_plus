# frozen_string_literal: true

module Decidim
  module Candidacies
    module Admin
      # A form object used to manage the candidacy answer in the
      # administration panel.
      class CandidacyAnswerForm < Form
        include TranslatableAttributes

        mimic :candidacy

        translatable_attribute :answer, Decidim::Attributes::RichText
        attribute :answer_url, String
        attribute :signature_start_date, Decidim::Attributes::LocalizedDate
        attribute :signature_end_date, Decidim::Attributes::LocalizedDate

        validates :signature_start_date, :signature_end_date, presence: true, if: :signature_dates_required?
        validates :signature_end_date, date: { after: :signature_start_date }, if: lambda { |form|
          form.signature_start_date.present? && form.signature_end_date.present?
        }

        def signature_dates_required?
          @signature_dates_required ||= context.candidacy.state == "open"
        end
      end
    end
  end
end
