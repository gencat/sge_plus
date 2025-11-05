# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20190125131847)
class AddDocumentNumberAuthorizationHandlerToCandidaciesTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_signature_collection_candidacies_types, :document_number_authorization_handler, :string
  end
end
