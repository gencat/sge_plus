# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Mailer for candidacies engine.
    class CandidaciesMailer < Decidim::ApplicationMailer
      include Decidim::TranslatableAttributes
      include Decidim::SanitizeHelper

      helper Decidim::TranslatableAttributes
      helper Decidim::SanitizeHelper

      # Notifies candidacy creation
      def notify_creation(candidacy)
        return if candidacy.author.email.blank?

        @candidacy = candidacy
        @organization = candidacy.organization

        with_user(candidacy.author) do
          @subject = I18n.t(
            "decidim.signature_collection.candidacies_mailer.creation_subject",
            title: translated_attribute(candidacy.title)
          )

          mail(to: "#{candidacy.author.name} <#{candidacy.author.email}>", subject: @subject)
        end
      end

      # Notify changes in state
      def notify_state_change(candidacy, user)
        return if user.email.blank?

        @organization = candidacy.organization

        with_user(user) do
          @subject = I18n.t(
            "decidim.signature_collection.candidacies_mailer.status_change_for",
            title: translated_attribute(candidacy.title)
          )

          @body = I18n.t(
            "decidim.signature_collection.candidacies_mailer.status_change_body_for",
            title: translated_attribute(candidacy.title),
            state: I18n.t(candidacy.state, scope: "decidim.signature_collection.admin_states")
          )

          @link = candidacy_url(candidacy, host: @organization.host)

          mail(to: "#{user.name} <#{user.email}>", subject: @subject)
        end
      end

      # Notify progress to all candidacy subscribers.
      def notify_progress(candidacy, user)
        return if user.email.blank?

        @organization = candidacy.organization
        @link = candidacy_url(candidacy, host: @organization.host)

        with_user(user) do
          @body = I18n.t(
            "decidim.signature_collection.candidacies_mailer.progress_report_body_for",
            title: translated_attribute(candidacy.title),
            percentage: candidacy.percentage
          )

          @subject = I18n.t(
            "decidim.signature_collection.candidacies_mailer.progress_report_for",
            title: translated_attribute(candidacy.title)
          )

          mail(to: "#{user.name} <#{user.email}>", subject: @subject)
        end
      end

      def notify_admins_validation(candidacy, admins)
        return if admins.blank?

        @candidacy = candidacy
        @organization = candidacy.organization
        @link = candidacy_url(candidacy, host: @organization.host)

        recipients = admins.pluck(:email)

        with_user(candidacy.author) do
          @subject = I18n.t(
            "decidim.signature_collection.candidacies_mailer.validation_subject",
            title: translated_attribute(candidacy.title)
          )

          mail(to: recipients, subject: @subject)
        end
      end
    end
  end
end
