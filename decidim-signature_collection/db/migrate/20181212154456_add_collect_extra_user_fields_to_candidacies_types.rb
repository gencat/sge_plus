# frozen_string_literal: true

class AddCollectExtraUserFieldsToCandidaciesTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :collect_user_extra_fields, :boolean, default: false
  end
end
