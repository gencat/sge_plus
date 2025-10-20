# frozen_string_literal: true

class AddHashtagToCandidacies < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies, :hashtag, :string, unique: true
  end
end
