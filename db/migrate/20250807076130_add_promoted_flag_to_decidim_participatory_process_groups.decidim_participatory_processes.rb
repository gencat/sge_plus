# frozen_string_literal: true

# This migration comes from decidim_participatory_processes (originally 20201030133444)
# This file has been modified by `decidim upgrade:migrations` task on 2025-09-03 08:54:23 UTC
class AddPromotedFlagToDecidimParticipatoryProcessGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_participatory_process_groups, :promoted, :boolean, default: false, index: true
  end
end
