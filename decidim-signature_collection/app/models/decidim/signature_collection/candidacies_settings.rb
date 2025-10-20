# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # Candidacies setting.
    class CandidaciesSettings < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"

      def self.log_presenter_class_for(_log)
        Decidim::SignatureCollection::AdminLog::CandidaciesSettingsPresenter
      end
    end
  end
end
