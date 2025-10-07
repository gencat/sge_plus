class AddCreateInitiativesEnabledToDecidimInitiativesSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_initiatives_settings, :creation_enabled, :boolean, default: true
  end
end
