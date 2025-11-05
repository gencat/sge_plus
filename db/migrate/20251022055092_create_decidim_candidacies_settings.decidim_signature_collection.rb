# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20220527130640)
class CreateDecidimCandidaciesSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_signature_collection_candidacies_settings do |t|
      t.string :candidacies_order, default: "random"
      t.references :decidim_organization, foreign_key: true, index: { name: "index_sig_coll_candidacies_settings_on_org_id" }
    end
  end
end
