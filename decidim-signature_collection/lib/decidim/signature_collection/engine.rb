# frozen_string_literal: true

require "rails"
require "active_support/all"
require "decidim/core"
require "decidim/signature_collection/content_blocks/registry_manager"
require "decidim/signature_collection/current_locale"
require "decidim/signature_collection/candidacy_slug"
require "decidim/signature_collection/menu"
require "decidim/signature_collection/query_extensions"

module Decidim
  module SignatureCollection
    # Decidim's SignatureCollection Rails Engine.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::SignatureCollection

      routes do
        get "/candidacy_types/search", to: "candidacy_types#search", as: :candidacy_types_search
        get "/candidacy_type_scopes/search", to: "candidacies_type_scopes#search", as: :candidacy_type_scopes_search
        get "/candidacy_type_signature_types/search", to: "candidacies_type_signature_types#search", as: :candidacy_type_signature_types_search

        resources :create_candidacy do
          collection do
            get :select_candidacy_type
            put :select_candidacy_type, to: "create_candidacy#store_candidacy_type"
            get :fill_data
            put :fill_data, to: "create_candidacy#store_data"
            get :promotal_committee
            get :finish
          end
        end

        get "candidacies/:candidacy_id", to: redirect { |params, _request|
          candidacy = Decidim::SignatureCollection::Candidacy.find(params[:candidacy_id])
          candidacy ? "/candidacies/#{candidacy.slug}" : "/404"
        }, constraints: { candidacy_id: /[0-9]+/ }

        get "/candidacies/:candidacy_id/f/:component_id", to: redirect { |params, _request|
          candidacy = Decidim::SignatureCollection::Candidacy.find(params[:candidacy_id])
          candidacy ? "/candidacies/#{candidacy.slug}/f/#{params[:component_id]}" : "/404"
        }, constraints: { candidacy_id: /[0-9]+/ }

        resources :candidacies, param: :slug, only: [:index, :show, :edit, :update], path: "candidacies" do
          resources :signatures, controller: "candidacy_signatures" do
            collection do
              get :fill_personal_data
              put :fill_personal_data, to: "candidacy_signatures#store_personal_data"
              get :sms_phone_number
              put :sms_phone_number, to: "candidacy_signatures#store_sms_phone_number"
              get :sms_code
              put :sms_code, to: "candidacy_signatures#store_sms_code"
              get :finish
              put :finish, to: "candidacy_signatures#store_finish"
            end
          end

          member do
            get :authorization_sign_modal, to: "authorization_sign_modals#show"
            get :authorization_create_modal, to: "authorization_create_modals#show"
            get :print, to: "candidacies#print", as: "print"
            get :send_to_technical_validation, to: "candidacies#send_to_technical_validation"
          end

          resource :candidacy_vote, only: [:create, :destroy]
          resources :committee_requests, only: [:new] do
            collection do
              get :spawn
            end
            member do
              get :approve
              delete :revoke
            end
          end
          resources :versions, only: [:show]
        end

        scope "/candidacies/:candidacy_slug/f/:component_id" do
          Decidim.component_manifests.each do |manifest|
            next unless manifest.engine

            constraints CurrentComponent.new(manifest) do
              mount manifest.engine, at: "/", as: "decidim_candidacy_#{manifest.name}"
            end
          end
        end
      end

      initializer "decidim_signature_collection.mount_routes" do
        Decidim::Core::Engine.routes do
          mount Decidim::SignatureCollection::Engine, at: "/", as: "decidim_candidacies"
        end
      end

      initializer "decidim_signature_collection.register_icons" do
        Decidim.icons.register(name: "Decidim::SignatureCollection::Candidacy", icon: "lightbulb-flash-line", description: "Candidacy", category: "activity",
                               engine: :signature_collection)
        Decidim.icons.register(name: "apps-line", icon: "apps-line", category: "system", description: "", engine: :signature_collection)
        Decidim.icons.register(name: "printer-line", icon: "printer-line", category: "system", description: "", engine: :signature_collection)
        Decidim.icons.register(name: "forbid-line", icon: "forbid-line", category: "system", description: "", engine: :signature_collection)
      end

      initializer "decidim_signature_collection.content_blocks" do
        Decidim::SignatureCollection::ContentBlocks::RegistryManager.register!
      end

      initializer "decidim_signature_collection.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::SignatureCollection::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::SignatureCollection::Engine.root}/app/views") # for partials
      end

      initializer "decidim_signature_collection.menu" do
        Decidim::SignatureCollection::Menu.register_menu!
        Decidim::SignatureCollection::Menu.register_mobile_menu!
        Decidim::SignatureCollection::Menu.register_home_content_block_menu!
      end

      initializer "decidim_signature_collection.badges" do
        Decidim::Gamification.register_badge(:signature_collection) do |badge|
          badge.levels = [1, 5, 15, 30, 50]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            case model
            when User
              Decidim::SignatureCollection::Candidacy.where(
                author: model,
                user_group: nil
              ).published.count
            when UserGroup
              Decidim::SignatureCollection::Candidacy.where(
                user_group: model
              ).published.count
            end
          }
        end
      end

      initializer "decidim_signature_collection.query_extensions" do
        Decidim::Api::QueryType.include QueryExtensions
      end

      initializer "decidim_signature_collection.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim_signature_collection.preview_mailer" do
        # Load in mailer previews for apps to use in development.
        # We need to make sure we call `Preview.all` before requiring our
        # previews, otherwise any previews the app attempts to add need to be
        # manually required.
        if Rails.env.development? || Rails.env.test?
          ActionMailer::Preview.all

          Dir[root.join("spec/mailers/previews/**/*_preview.rb")].each do |file|
            require_dependency file
          end
        end
      end

      initializer "decidim_signature_collection.authorization_transfer" do
        config.to_prepare do
          Decidim::AuthorizationTransfer.register(:signature_collection) do |transfer|
            transfer.move_records(Decidim::SignatureCollection::Candidacy, :decidim_author_id)
            transfer.move_records(Decidim::SignatureCollection::CandidaciesVote, :decidim_author_id)
          end
        end
      end
    end
  end
end
