# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20170927153744)
class ChangeSignatureIntervalToOptional < ActiveRecord::Migration[5.1]
  def change
    change_column :decidim_signature_collection_candidacies, :signature_start_time, :date, null: true
    change_column :decidim_signature_collection_candidacies, :signature_end_time, :date, null: true
  end
end
