# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171011110714)
class AddBannerImageToCandidacyType < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies_types, :banner_image, :string
  end
end
