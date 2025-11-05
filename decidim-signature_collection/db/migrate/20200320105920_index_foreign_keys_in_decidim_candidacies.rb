# frozen_string_literal: true

class IndexForeignKeysInDecidimCandidacies < ActiveRecord::Migration[5.2]
  def change
    add_index :decidim_signature_collection_candidacies, :decidim_user_group_id, name: "idx_signaturecollect_candidacies_on_user_group_id"
    add_index :decidim_signature_collection_candidacies, :scoped_type_id, name: "idx_signaturecollect_candidacies_on_scoped_type_id"
  end
end
