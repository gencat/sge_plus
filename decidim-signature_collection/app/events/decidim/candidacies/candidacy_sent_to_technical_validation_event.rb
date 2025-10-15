# frozen_string_literal: true

module Decidim
  module Candidacies
    class CandidacySentToTechnicalValidationEvent < Decidim::Events::SimpleEvent
      include Rails.application.routes.mounted_helpers

      i18n_attributes :admin_candidacy_url, :admin_candidacy_path

      def admin_candidacy_path
        ResourceLocatorPresenter.new(resource).edit
      end

      def admin_candidacy_url
        EngineRouter.admin_proxy(resource).edit_candidacy_url(resource)
      end
    end
  end
end
