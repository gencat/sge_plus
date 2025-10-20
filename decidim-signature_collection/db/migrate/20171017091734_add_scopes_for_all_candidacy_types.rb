# frozen_string_literal: true

class AddScopesForAllCandidacyTypes < ActiveRecord::Migration[5.1]
  class Scope < ApplicationRecord
    self.table_name = :decidim_scopes
  end

  class Organization < ApplicationRecord
    self.table_name = :decidim_organizations

    has_many :scopes, foreign_key: "decidim_organization_id", class_name: "Scope"
  end

  class CandidaciesType < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies_types

    belongs_to :organization,
               foreign_key: "decidim_organization_id",
               class_name: "Organization"
  end

  class CandidaciesTypeScope < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies_type_scopes
  end

  def up
    # This migrantion intent is simply to keep seed data at staging
    # environment consistent with the underlying data model. It is
    # not relevant for production environments.
    Organization.find_each do |organization|
      CandidaciesType.where(organization:).find_each do |type|
        organization.scopes.each do |scope|
          CandidaciesTypeScope.create(
            decidim_signature_collection_candidacies_type_id: type.id,
            decidim_scopes_id: scope.id,
            supports_required: 1000
          )
        end
      end
    end
  end

  def down
    Decidim::CandidaciesTypeScope.destroy_all
  end
end
