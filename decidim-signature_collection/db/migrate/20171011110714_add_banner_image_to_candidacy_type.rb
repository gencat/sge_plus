# frozen_string_literal: true

class AddBannerImageToCandidacyType < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies_types, :banner_image, :string
  end
end
