# frozen_string_literal: true

require "digest/sha1"

module Decidim
  module SignatureCollection
    # Candidacies can be voted by users and supported by organizations.
    class CandidaciesVote < ApplicationRecord
      include Decidim::TranslatableAttributes

      belongs_to :candidacy,
                 foreign_key: "decidim_signature_collection_candidacy_id",
                 class_name: "Decidim::SignatureCollection::Candidacy",
                 inverse_of: :votes

      scope :with_xml_signed, -> { where.not(encrypted_xml_doc_signed: nil) }

      after_commit :update_counter_cache, on: [:create, :destroy]

      validates :candidacy, uniqueness: { scope: :hash_id }, on: :create

      # Public: Generates a hashed representation of the candidacy support.
      #
      # Used when exporting the votes as CSV.
      def sha1
        title = translated_attribute(candidacy.title)
        description = translated_attribute(candidacy.description)

        Digest::SHA1.hexdigest "#{hash_id}#{title}#{description}"
      end

      def decrypted_metadata
        @decrypted_metadata ||= encrypted_metadata ? encryptor.decrypt(encrypted_metadata) : {}
      end

      private

      def encryptor
        @encryptor ||= Decidim::SignatureCollection::DataEncryptor.new(secret: "personal user metadata")
      end

      def update_counter_cache
        candidacy.update_online_votes_counters
      end
    end
  end
end
