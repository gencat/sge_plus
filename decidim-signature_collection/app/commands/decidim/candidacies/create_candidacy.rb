# frozen_string_literal: true

require "decidim/components/namer"

module Decidim
  module Candidacies
    # A command with all the business logic that creates a new candidacy.
    class CreateCandidacy < Decidim::Command
      include CurrentLocale
      include ::Decidim::MultipleAttachmentsMethods
      include ::Decidim::GalleryMethods

      delegate :current_user, to: :form
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      def initialize(form)
        @form = form
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

        candidacy = create_candidacy

        if candidacy.persisted?
          broadcast(:ok, candidacy)
        else
          broadcast(:invalid, candidacy)
        end
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

      attr_reader :form, :attachment, :candidacy

      # Creates the candidacy and all default components
      def create_candidacy
        build_candidacy
        return candidacy unless candidacy.valid?

        with_events(with_transaction: true) do
          candidacy.save!

          @attached_to = candidacy
          create_attachments if process_attachments?
          create_gallery if process_gallery?

          create_components_for(candidacy)
          send_notification(candidacy)
          add_author_as_follower(candidacy)
          add_author_as_committee_member(candidacy)
        end

        candidacy
      end

      def build_candidacy
        @candidacy = Candidacy.new(
          organization: form.current_organization,
          title: { current_locale => form.title },
          description: { current_locale => form.description },
          author: current_user,
          scoped_type:,
          signature_type: form.type.signature_type,
          decidim_user_group_id: form.decidim_user_group_id,
          decidim_area_id: form.area_id,
          state: "created"
        )
      end

      def scoped_type
        CandidacysTypeScope.order(:id).find_by(type: form.type, scope: form.scope)
      end

      def signature_end_date
        return nil unless form.context.candidacy_type.custom_signature_end_date_enabled?

        form.signature_end_date
      end

      def area
        return nil unless form.context.candidacy_type.area_enabled?

        form.area
      end

      def create_components_for(candidacy)
        Decidim::Candidacies.default_components.each do |component_name|
          component = Decidim::Component.create!(
            name: Decidim::Components::Namer.new(candidacy.organization.available_locales, component_name).i18n_name,
            manifest_name: component_name,
            published_at: Time.current,
            participatory_space: candidacy
          )

          initialize_pages(component) if component_name.in? ["pages", :pages]
        end
      end

      def initialize_pages(component)
        Decidim::Pages::CreatePage.call(component) do
          on(:invalid) { raise "Cannot create page" }
        end
      end

      def send_notification(candidacy)
        Decidim::EventsManager.publish(
          event: "decidim.events.candidacies.candidacy_created",
          event_class: Decidim::Candidacies::CreateCandidacyEvent,
          resource: candidacy,
          followers: candidacy.author.followers
        )
      end

      def add_author_as_follower(candidacy)
        form = Decidim::FollowForm
               .from_params(followable_gid: candidacy.to_signed_global_id.to_s)
               .with_context(
                 current_organization: candidacy.organization,
                 current_user:
               )

        Decidim::CreateFollow.new(form).call
      end

      def add_author_as_committee_member(candidacy)
        form = Decidim::Candidacies::CommitteeMemberForm
               .from_params(candidacy_id: candidacy.id, user_id: candidacy.decidim_author_id, state: "accepted")
               .with_context(
                 current_organization: candidacy.organization,
                 current_user:
               )

        Decidim::Candidacies::SpawnCommitteeRequest.new(form).call
      end
    end
  end
end
