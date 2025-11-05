# frozen_string_literal: true

class UpdateCandidacyScopedType < ActiveRecord::Migration[5.1]
  class CandidaciesTypeScope < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies_type_scopes
  end

  class Scope < ApplicationRecord
    self.table_name = :decidim_scopes

    # Scope to return only the top level scopes.
    #
    # Returns an ActiveRecord::Relation.
    def self.top_level
      where parent_id: nil
    end
  end

  class Organization < ApplicationRecord
    self.table_name = :decidim_organizations

    has_many :scopes, foreign_key: "decidim_organization_id", class_name: "Scope"

    # Returns top level scopes for this organization.
    #
    # Returns an ActiveRecord::Relation.
    def top_scopes
      @top_scopes ||= scopes.top_level
    end
  end

  class Candidacy < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies

    belongs_to :scoped_type,
               class_name: "CandidaciesTypeScope"

    belongs_to :organization,
               foreign_key: "decidim_organization_id",
               class_name: "Organization"
  end

  def up
    Candidacy.find_each do |candidacy|
      candidacy.scoped_type = CandidaciesTypeScope.find_by(
        decidim_signature_collection_candidacies_type_id: candidacy.type_id,
        decidim_scopes_id: candidacy.decidim_scope_id || candidacy.organization.top_scopes.first
      )

      candidacy.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot undo initialization of mandatory attribute"
  end
end
