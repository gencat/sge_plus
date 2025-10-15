# frozen_string_literal: true

module Decidim
  module Candidacies
    # Exposes Candidacies versions so users can see how an Candidacy
    # has been updated through time.
    class VersionsController < Decidim::Candidacies::ApplicationController
      include ParticipatorySpaceContext
      helper CandidacyHelper

      include NeedsCandidacy
      include Decidim::ResourceVersionsConcern

      def versioned_resource
        current_candidacy
      end

      private

      def current_participatory_space_manifest
        @current_participatory_space_manifest ||= Decidim.find_participatory_space_manifest(:candidacies)
      end
    end
  end
end
