# frozen_string_literal: true

class AddFollowableCounterCacheToCandidacies < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies, :follows_count, :integer, null: false, default: 0, index: true

    reversible do |dir|
      dir.up do
        Decidim::SignatureCollection::Candidacy.reset_column_information
        Decidim::SignatureCollection::Candidacy.find_each do |record|
          record.class.reset_counters(record.id, :follows)
        end
      end
    end
  end
end
