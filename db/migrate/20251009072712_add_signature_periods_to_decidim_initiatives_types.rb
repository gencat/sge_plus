# frozen_string_literal: true
class AddSignaturePeriodsToDecidimInitiativesTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_initiatives_types, :signature_period_start, :datetime
    add_column :decidim_initiatives_types, :signature_period_end, :datetime
    add_column :decidim_initiatives_types, :published, :boolean, default: true
  end
end
