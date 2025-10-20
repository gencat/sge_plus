# frozen_string_literal: true

class AddCommentableCounterCacheToCandidacies < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies, :comments_count, :integer, null: false, default: 0, index: true
    Decidim::SignatureCollection::Candidacy.reset_column_information
    Decidim::SignatureCollection::Candidacy.find_each(&:update_comments_count)
  end
end
