# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171011152425)
class AddHashtagToCandidacies < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies, :hashtag, :string, unique: true
  end
end
