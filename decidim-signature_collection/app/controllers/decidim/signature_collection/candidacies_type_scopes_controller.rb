# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Exposes the candidacy type text search so users can choose a type writing its name.
    class CandidaciesTypeScopesController < Decidim::SignatureCollection::ApplicationController
      helper_method :scoped_types

      # GET /candidacy_type_scopes/search
      def search
        enforce_permission_to :search, :candidacy_type_scope
        render layout: false
      end

      private

      def scoped_types
        @scoped_types ||= if candidacy_type.only_global_scope_enabled?
                            candidacy_type.scopes.where(scope: nil)
                          else
                            candidacy_type.scopes
                          end
      end

      def candidacy_type
        @candidacy_type ||= CandidaciesType.where(organization: current_organization).find(params[:type_id])
      end
    end
  end
end
