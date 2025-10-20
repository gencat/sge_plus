# frozen_string_literal: true

class CreateCandidacyDescriptionIndex < ActiveRecord::Migration[5.1]
  def up
    execute "CREATE INDEX decidim_candidacies_description_search ON decidim_signature_collection_candidacies(md5(description::text))"
  end

  def down
    execute "DROP INDEX decidim_candidacies_description_search"
  end
end
