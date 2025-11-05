# frozen_string_literal: true

class RemoveSupportsRequiredFromDecidimCandidaciesTypes < ActiveRecord::Migration[5.1]
  def change
    remove_column :decidim_signature_collection_candidacies_types, :supports_required, :integer, null: false
  end
end
