# frozen_string_literal: true

module Decidim
  module SignatureCollection
    module Admin
      # A command with all the business logic to answer
      # candidacies.
      class UpdateCandidacyAnswer < Decidim::Command
        delegate :current_user, to: :form
        # Public: Initializes the command.
        #
        # candidacy   - Decidim::SignatureCollection::Candidacy
        # form         - A form object with the params.
        def initialize(candidacy, form)
          @form = form
          @candidacy = candidacy
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form was not valid and we could not proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          @candidacy = Decidim.traceability.update!(
            candidacy,
            current_user,
            attributes
          )
          notify_candidacy_is_extended if @notify_extended
          broadcast(:ok, candidacy)
        rescue ActiveRecord::RecordInvalid
          broadcast(:invalid, candidacy)
        end

        private

        attr_reader :form, :candidacy

        def attributes
          attrs = {
            answer: form.answer,
            answer_url: form.answer_url
          }

          attrs[:answered_at] = Time.current if form.answer.present?

          if form.signature_dates_required?
            attrs[:signature_start_date] = form.signature_start_date
            attrs[:signature_end_date] = form.signature_end_date

            if candidacy.published? && form.signature_end_date != candidacy.signature_end_date &&
               form.signature_end_date > candidacy.signature_end_date
              @notify_extended = true
            end
          end

          attrs
        end

        def notify_candidacy_is_extended
          Decidim::EventsManager.publish(
            event: "decidim.events.signature_collection.candidacy_extended",
            event_class: Decidim::SignatureCollection::ExtendCandidacyEvent,
            resource: candidacy,
            followers: candidacy.followers - [candidacy.author]
          )
        end
      end
    end
  end
end
