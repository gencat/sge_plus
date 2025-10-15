# frozen_string_literal: true

module Decidim
  # Candidacies setting.
  class CandidacysSettings < ApplicationRecord
    include Decidim::Traceable
    include Decidim::Loggable

    belongs_to :organization,
               foreign_key: "decidim_organization_id",
               class_name: "Decidim::Organization"

    def self.log_presenter_class_for(_log)
      Decidim::Candidacies::AdminLog::CandidacysSettingsPresenter
    end
  end
end
