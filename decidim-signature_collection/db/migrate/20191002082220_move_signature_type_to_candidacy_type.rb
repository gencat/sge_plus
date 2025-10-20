# frozen_string_literal: true

class MoveSignatureTypeToCandidacyType < ActiveRecord::Migration[5.2]
  class CandidaciesType < ApplicationRecord
    self.table_name = :decidim_signature_collection_candidacies_types
  end

  def change
    if !ActiveRecord::Base.connection.table_exists?("decidim_signature_collection_candidacies_types")
      Rails.logger.info "Skipping migration since there is no CandidaciesType table"
      return
    elsif CandidaciesType.count.positive?
      raise "You need to edit this migration to continue"
    end

    # This flag says when mixed and face-to-face voting methods
    # are allowed. If set to false, only online voting will be
    # allowed
    # face_to_face_voting_allowed = true

    add_column :decidim_signature_collection_candidacies_types, :signature_type, :integer, null: false, default: 0

    CandidaciesType.reset_column_information

    CandidaciesType.find_each do |type|
      type.signature_type = if type.online_signature_enabled && face_to_face_voting_allowed
                              :any
                            elsif type.online_signature_enabled && !face_to_face_voting_allowed
                              :online
                            else
                              :offline
                            end
      type.save!
    end

    remove_column :decidim_signature_collection_candidacies_types, :online_signature_enabled
  end
end
