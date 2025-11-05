# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20190124170442)
class AddValidateSmsCodeOnVotesToCandidaciesTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :validate_sms_code_on_votes, :boolean, default: false
  end
end
