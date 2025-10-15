# frozen_string_literal: true

require "decidim/components/namer"
require "decidim/seeds"

module Decidim
  module Candidacies
    class Seeds < Decidim::Seeds
      def call
        create_content_block!

        3.times do |_n|
          type = create_candidacy_type!

          organization.top_scopes.each do |scope|
            create_candidacy_type_scope!(scope:, type:)
          end
        end

        Decidim::Candidacy.states.keys.each do |state|
          Decidim::Candidacy.skip_callback(:save, :after, :notify_state_change, raise: false)
          Decidim::Candidacy.skip_callback(:create, :after, :notify_creation, raise: false)

          candidacy = create_candidacy!(state:)

          create_candidacy_votes!(candidacy:) if %w(published rejected accepted).include? state

          Decidim::Comments::Seed.comments_for(candidacy)

          create_attachment(attached_to: candidacy, filename: "city.jpeg")

          Decidim::Candidacies.default_components.each do |component_name|
            create_component!(candidacy:, component_name:)
          end
        end
      end

      def create_content_block!
        Decidim::ContentBlock.create(
          organization:,
          weight: 33,
          scope_name: :homepage,
          manifest_name: :highlighted_candidacies,
          published_at: Time.current
        )
      end

      def create_candidacy_type!
        Decidim::CandidacysType.create!(
          title: Decidim::Faker::Localized.sentence(word_count: 5),
          description: Decidim::Faker::Localized.sentence(word_count: 25),
          organization:,
          banner_image: ::Faker::Boolean.boolean(true_ratio: 0.5) ? banner_image : nil # Keep after organization
        )
      end

      def create_candidacy_type_scope!(scope:, type:)
        n = rand(3)
        Decidim::CandidacysTypeScope.create(
          type:,
          scope:,
          supports_required: (n + 1) * 1000
        )
      end

      def create_candidacy!(state:)
        published_at = %w(published rejected accepted).include?(state) ? 7.days.ago : nil

        params = {
          title: Decidim::Faker::Localized.sentence(word_count: 3),
          description: Decidim::Faker::Localized.sentence(word_count: 25),
          scoped_type: Decidim::CandidacysTypeScope.all.sample,
          state:,
          signature_type: "online",
          signature_start_date: Date.current - 7.days,
          signature_end_date: Date.current + 7.days,
          published_at:,
          author: Decidim::User.all.sample,
          organization:
        }

        candidacy = Decidim.traceability.perform_action!(
          "publish",
          Decidim::Candidacy,
          organization.users.first,
          visibility: "all"
        ) do
          Decidim::Candidacy.create!(params)
        end
        candidacy.add_to_index_as_search_resource

        candidacy
      end

      def create_candidacy_votes!(candidacy:)
        users = []
        rand(50).times do
          author = (Decidim::User.all - users).sample
          candidacy.votes.create!(author:, scope: candidacy.scope, hash_id: SecureRandom.hex)
          users << author
        end
      end

      def create_component!(candidacy:, component_name:)
        component = Decidim::Component.create!(
          name: Decidim::Components::Namer.new(candidacy.organization.available_locales, component_name).i18n_name,
          manifest_name: component_name,
          published_at: Time.current,
          participatory_space: candidacy
        )

        return unless component_name.in? ["pages", :pages]

        Decidim::Pages::CreatePage.call(component) do
          on(:invalid) { raise "Cannot create page" }
        end
      end
    end
  end
end
