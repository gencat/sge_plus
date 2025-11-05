# frozen_string_literal: true

# i18n-tasks-use t('decidim.signature_collection.show.badge_name.accepted')
# i18n-tasks-use t('decidim.signature_collection.show.badge_name.created')
# i18n-tasks-use t('decidim.signature_collection.show.badge_name.discarded')
# i18n-tasks-use t('decidim.signature_collection.show.badge_name.open')
# i18n-tasks-use t('decidim.signature_collection.show.badge_name.rejected')
# i18n-tasks-use t('decidim.signature_collection.show.badge_name.validating')
#
module Decidim
  module SignatureCollection
    # Exposes the candidacy type text search so users can choose a type writing its name.
    class CandidacyTypesController < Decidim::SignatureCollection::ApplicationController
      # GET /candidacy_types/search
      def search
        enforce_permission_to :search, :candidacy_type

        types = FreetextCandidacyTypes.for(current_organization, I18n.locale, params[:term])
        render json: { results: types.map { |type| { id: type.id.to_s, text: type.title[I18n.locale.to_s] } } }
      end
    end
  end
end
