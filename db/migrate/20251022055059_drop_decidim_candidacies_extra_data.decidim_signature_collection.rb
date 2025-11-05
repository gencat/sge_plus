# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171204094639)
class DropDecidimCandidaciesExtraData < ActiveRecord::Migration[5.1]
  def up
    drop_table :decidim_signature_collection_candidacies_extra_data
  end

  def down
    create_table :decidim_signature_collection_candidacies_extra_data do |t|
      t.references :decidim_candidacy, null: false, index: true
      t.integer :data_type, null: false, default: 0
      t.jsonb :data, null: false
    end
  end
end
