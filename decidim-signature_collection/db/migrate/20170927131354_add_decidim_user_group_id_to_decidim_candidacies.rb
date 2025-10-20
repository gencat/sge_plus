# frozen_string_literal: true

class AddDecidimUserGroupIdToDecidimCandidacies < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies,
               :decidim_user_group_id, :integer, index: { name: "idx_signaturecollect_candidacies_on_user_group_id" }
  end
end
