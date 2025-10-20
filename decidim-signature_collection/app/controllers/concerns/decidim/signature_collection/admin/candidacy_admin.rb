# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module SignatureCollection
    module Admin
      # This concern is meant to be included in all controllers that are scoped
      # into an candidacy's admin panel. It will override the layout so it shows
      # the sidebar, preload the assembly, etc.
      module CandidacyAdmin
        extend ActiveSupport::Concern
        include CandidacySlug

        included do
          include NeedsCandidacy

          include Decidim::Admin::ParticipatorySpaceAdminContext
          participatory_space_admin_layout

          alias_method :current_participatory_space, :current_candidacy
          alias_method :current_participatory_space_manifest, :candidacies_manifest
        end

        private

        def candidacies_manifest
          @candidacies_manifest ||= Decidim.find_participatory_space_manifest(:candidacies)
        end
      end
    end
  end
end
