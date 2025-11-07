# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # A command with all the business logic that updates an
    # existing candidacy.
    class UpdateCandidacy < Decidim::Command
      include ::Decidim::MultipleAttachmentsMethods
      include ::Decidim::GalleryMethods
      include CurrentLocale
      delegate :current_user, to: :form

      # Public: Initializes the command.
      #
      # candidacy - Decidim::SignatureCollection::Candidacy
      # form       - A form object with the params.
      def initialize(candidacy, form)
        @form = form
        @candidacy = candidacy
        @attached_to = candidacy
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form was not valid and we could not proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if process_attachments?
          build_attachments
          return broadcast(:invalid) if attachments_invalid?
        end

        if process_gallery?
          build_gallery
          return broadcast(:invalid) if gallery_invalid?
        end

        with_events(with_transaction: true) do
          @candidacy = Decidim.traceability.update!(
            candidacy,
            current_user,
            attributes
          )

          photo_cleanup!
          document_cleanup!
          create_attachments if process_attachments?
          create_gallery if process_gallery?
        end

        broadcast(:ok, candidacy)
      rescue ActiveRecord::RecordInvalid
        broadcast(:invalid, candidacy)
      end

      protected

      def event_arguments
        {
          resource: candidacy,
          extra: {
            event_author: form.current_user,
            locale:
          }
        }
      end

      private

      attr_reader :form, :candidacy

      def attributes
        attrs = {
          title: { current_locale => form.title },
          description: { current_locale => form.description },
          decidim_user_group_id: form.decidim_user_group_id
        }

        if form.signature_type_updatable?
          attrs[:signature_type] = form.signature_type
          attrs[:scoped_type_id] = form.scoped_type_id if form.scoped_type_id
        end

        if candidacy.created?
          attrs[:signature_end_date] = form.signature_end_date if candidacy.custom_signature_end_date_enabled?
          attrs[:decidim_area_id] = form.area_id if candidacy.area_enabled?
        end

        attrs
      end
    end
  end
end
