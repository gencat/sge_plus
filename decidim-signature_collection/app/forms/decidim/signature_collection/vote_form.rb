# frozen_string_literal: true

module Decidim
  module SignatureCollection
    # A form object used to collect the data for a new candidacy.
    class VoteForm < Form
      include TranslatableAttributes

      mimic :candidacies_vote

      attribute :name, String
      attribute :first_surname, String
      attribute :second_surname, String
      attribute :document_type, Integer
      attribute :document_number, String
      attribute :date_of_birth, Date

      attribute :postal_code, String
      attribute :encrypted_xml_doc_signed, String
      attribute :encrypted_xml_doc_to_sign, String
      attribute :hash_id, String

      attribute :candidacy, Decidim::SignatureCollection::Candidacy

      validates :candidacy, presence: true

      validate :already_voted?
      validate :document_number_format

      validates :name, :first_surname, :document_type, :document_number, :date_of_birth, :postal_code, presence: true

      delegate :scope, to: :candidacy

      def self.document_types
        { nif: 1, nie: 2 }
      end

      # Public: The hash to uniquely identify an candidacy vote
      #
      # Returns a String.
      def hash_id
        return unless candidacy && document_number

        @hash_id ||= Digest::MD5.hexdigest(
          [
            candidacy.id,
            document_number,
            Rails.application.secret_key_base
          ].compact.join("-")
        )
      end

      def filename
        "#{document_number}.xml"
      end

      def encrypted_metadata
        metadata = {
          name:,
          first_surname:,
          second_surname:,
          document_type:,
          document_number:,
          date_of_birth:,
          postal_code:
        }
        encryptor.encrypt(metadata)
      end

      def encrypted_xml_doc_to_sign
        xml = Decidim::SignatureCollection::XmlBuilder.new({
                                                             candidacy:,
                                                             name:,
                                                             first_surname:,
                                                             second_surname:,
                                                             document_type:,
                                                             document_number:,
                                                             date_of_birth:
                                                           }).build

        encryptor.encrypt(xml)
      end

      protected

      # Private: Checks if there is any existing vote that matches the user's data.
      def already_voted?
        return false if hash_id.blank?

        errors.add(:document_number, :taken) if candidacy.votes.exists?(hash_id: hash_id)
      end

      def document_number_format
        return if document_number.blank? || document_type.blank?

        case document_type
        when self.class.document_types[:nif]
          validate_nif_format
        when self.class.document_types[:nie]
          validate_nie_format
        end
      end

      def validate_nif_format
        nif_regex = /\A\d{8}[A-Z]\z/i
        unless document_number.to_s.upcase.match?(nif_regex)
          errors.add(:document_number, :invalid_nif_format)
          return
        end

        validate_nif_letter
      end

      def validate_nie_format
        nie_regex = /\A[XYZ]\d{7}[A-Z]\z/i
        unless document_number.to_s.upcase.match?(nie_regex)
          errors.add(:document_number, :invalid_nie_format)
          return
        end

        validate_nie_letter
      end

      def validate_nif_letter
        letters = "TRWAGMYFPDXBNJZSQVHLCKE"
        doc = document_number.to_s.upcase
        number = doc[0..7].to_i
        letter = doc[8]
        expected_letter = letters[number % 23]

        errors.add(:document_number, :invalid_nif_letter) unless letter == expected_letter
      end

      def validate_nie_letter
        letters = "TRWAGMYFPDXBNJZSQVHLCKE"
        doc = document_number.to_s.upcase

        nie_number = doc.dup
        nie_number[0] = "0" if doc[0] == "X"
        nie_number[0] = "1" if doc[0] == "Y"
        nie_number[0] = "2" if doc[0] == "Z"

        number = nie_number[0..7].to_i
        letter = doc[8]
        expected_letter = letters[number % 23]

        errors.add(:document_number, :invalid_nie_letter) unless letter == expected_letter
      end

      def encryptor
        @encryptor ||= DataEncryptor.new(secret: Rails.application.secret_key_base)
      end
    end
  end
end
