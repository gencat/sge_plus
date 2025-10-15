# frozen_string_literal: true

# This migration comes from decidim_accountability (originally 20180508170647)
# This file has been modified by `decidim upgrade:migrations` task on 2025-10-15 08:46:24 UTC
class AddExternalIdToResults < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_accountability_results, :external_id, :string
    add_index :decidim_accountability_results, :external_id
  end
end
