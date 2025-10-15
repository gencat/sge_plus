# frozen_string_literal: true

require "rails"
require "active_support/all"
require "decidim/core"
require "decidim/candidacies/menu"

module Decidim
  module Candidacies
    # Decidim's Assemblies Rails Admin Engine.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Candidacies::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        constraints(->(request) { Decidim::Admin::OrganizationDashboardConstraint.new(request).matches? }) do
          resources :candidacies_types, except: :show do
            resource :permissions, controller: "candidacies_types_permissions"
            resources :candidacies_type_scopes, except: [:index, :show]
          end

          resources :candidacies_settings, only: [:edit, :update], controller: "candidacies_settings"

          resources :candidacies, only: [:index, :edit, :update], param: :slug do
            member do
              get :send_to_technical_validation
              post :publish
              delete :unpublish
              delete :discard
              get :export_votes
              get :export_pdf_signatures
              post :accept
              delete :reject
            end

            collection do
              get :export
            end

            resources :attachments, controller: "candidacy_attachments", except: [:show]

            resources :committee_requests, only: [:index] do
              member do
                get :approve
                delete :revoke
              end
            end

            resource :permissions, controller: "candidacies_permissions"

            resource :answer, only: [:edit, :update]
          end

          scope "/candidacies/:candidacy_slug" do
            resources :components do
              collection do
                put :reorder
                get :manage_trash, to: "components#manage_trash"
              end
              resource :permissions, controller: "component_permissions"
              member do
                put :publish
                put :unpublish
                get :share
                put :hide
                patch :soft_delete
                patch :restore
              end
              resources :component_share_tokens, except: [:show], path: "share_tokens", as: "share_tokens"
              resources :exports, only: :create
            end

            resources :moderations do
              member do
                put :unreport
                put :hide
                put :unhide
              end
              patch :bulk_action, on: :collection
              resources :reports, controller: "moderations/reports", only: [:index, :show]
            end

            resources :candidacy_share_tokens, except: [:show], path: "share_tokens"
          end

          scope "/candidacies/:candidacy_slug/components/:component_id/manage" do
            Decidim.component_manifests.each do |manifest|
              next unless manifest.admin_engine

              constraints CurrentComponent.new(manifest) do
                mount manifest.admin_engine, at: "/", as: "decidim_admin_candidacy_#{manifest.name}"
              end
            end
          end
        end
      end

      initializer "decidim_candidacies_admin.mount_routes" do |_app|
        Decidim::Core::Engine.routes do
          mount Decidim::Candidacies::AdminEngine, at: "/admin", as: "decidim_admin_candidacies"
        end
      end

      initializer "decidim_candidacies_admin.menu" do
        Decidim::Candidacies::Menu.register_admin_menu_modules!
        Decidim::Candidacies::Menu.register_admin_candidacies_components_menu!
        Decidim::Candidacies::Menu.register_admin_candidacy_menu!
        Decidim::Candidacies::Menu.register_admin_candidacy_actions_menu!
        Decidim::Candidacies::Menu.register_admin_candidacies_menu!
      end
    end
  end
end
