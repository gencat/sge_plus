# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171102094556)
class CreateCandidacyDescriptionIndex < ActiveRecord::Migration[5.1]
  def up
    execute "CREATE INDEX decidim_candidacies_description_search ON decidim_signature_collection_candidacies(md5(description::text))"
  end

  def down
    execute "DROP INDEX decidim_candidacies_description_search"
  end
end
