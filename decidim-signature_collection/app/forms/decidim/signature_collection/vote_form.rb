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
      attribute :encrypted_metadata, String
      attribute :hash_id, String

      attribute :candidacy, Decidim::SignatureCollection::Candidacy

      validates :candidacy, presence: true
      # TO REVIEW
      # validates :authorized_scopes, presence: true

      validate :already_voted?
      validate :document_number_format

      validates :name, :first_surname, :document_type, :document_number, :date_of_birth, :postal_code, presence: true

      delegate :scope, to: :candidacy

      def self.document_types
        { nif: 1, nie: 2 }
      end

      def encrypted_metadata
        @encrypted_metadata ||= encryptor.encrypt(metadata)
      end

      # Public: The hash to uniquely identify an candidacy vote. It uses the
      # candidacy scope as a default.
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

      # Public: Builds the list of scopes where the user is authorized to vote in. This is used when
      # the candidacy allows also voting on child scopes, not only the main scope.
      #
      # Instead of just listing the children of the main scope, we just want to select the ones that
      # have been added to the CandidacyType with its voting settings.
      #
      def authorized_scopes
        candidacy.votable_candidacy_type_scopes.select do |candidacy_type_scope|
          candidacy_type_scope.global_scope? ||
            candidacy_type_scope.scope == user_authorized_scope ||
            candidacy_type_scope.scope.ancestor_of?(user_authorized_scope)
        end.map(&:scope).compact.uniq
      end

      # Public: Finds the scope the user has an authorization for, this way the user can vote
      # on that scope and its parents.
      #
      # This is can be used to allow users that are authorized with a children
      # scope to sign an candidacy with a parent scope.
      #
      # As an example: A city (global scope) has many districts (scopes with
      # parent nil), and each district has different neighbourhoods (with its
      # parent as a district). If we setup the authorization handler to match
      # a neighbourhood, the same authorization can be used to participate
      # in district, neighbourhoods or city candidacies.
      #
      # Returns a Decidim::Scope.
      def user_authorized_scope
        return scope if handler_name.blank?
        return scope unless authorized?
        return scope if authorization.metadata.blank?

        @user_authorized_scope ||= authorized_scope_candidates.find do |scope|
          scope&.id == authorization.metadata.symbolize_keys[:scope_id]
        end || scope
      end

      # Public: Builds a list of Decidim::Scopes where the user could have a
      # valid authorization.
      #
      # If the candidacy is set with a global scope (meaning the scope is nil),
      # all the scopes in the organization are valid.
      #
      # Returns an array of Decidim::Scopes.
      def authorized_scope_candidates
        authorized_scope_candidates = [candidacy.scope]
        authorized_scope_candidates += if candidacy.scope.present?
                                         candidacy.scope.descendants
                                       else
                                         candidacy.organization.scopes
                                       end
        authorized_scope_candidates.uniq
      end

      def metadata
        {
          name:,
          first_surname:,
          second_surname:,
          document_type:,
          document_number:,
          date_of_birth:,
          postal_code:
        }
      end

      protected

      # Private: Checks if there is any existing vote that matches the user's data.
      def already_voted?
        return unless hash_id.present?
        
        authorized_scopes.each do |authorized_scope|
          if candidacy.votes.exists?(hash_id: hash_id, scope: authorized_scope)
            errors.add(:document_number, :taken)
            break
          end
        end
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
        nie_number[0] = '0' if doc[0] == 'X'
        nie_number[0] = '1' if doc[0] == 'Y'
        nie_number[0] = '2' if doc[0] == 'Z'
        
        number = nie_number[0..7].to_i
        letter = doc[8]
        expected_letter = letters[number % 23]
        
        errors.add(:document_number, :invalid_nie_letter) unless letter == expected_letter
      end

      def author
        @author ||= current_organization.users.find_by(id: author_id)
      end

      # Private: Finds an authorization for the user signing the candidacy and
      # the configured handler.
      # def authorization
      #   return unless signer && handler_name

      #   @authorization ||= Verifications::Authorizations.new(
      #     organization: signer.organization,
      #     user: signer,
      #     name: handler_name
      #   ).first
      # end

      # Private: Checks if the authorization has not expired or is invalid.
      # def authorized?
      #   authorization_status&.first == :ok
      # end

      # Private: Builds an authorization handler with the data the user provided
      # when signing the candidacy.
      #
      # This is currently tied to authorization handlers that have, at least, these attributes:
      #   * document_type
      #   * document_number
      #   * name
      #   * first_surname
      #   * second_surname
      #   * date_of_birth
      #   * postal_code
      #
      # Once we have the authorization handler we can use is to compute the
      # unique_id and compare it to an existing authorization.
      #
      # Returns a Decidim::AuthorizationHandler.
      # def authorization_handler
      #   return unless document_number && handler_name && signer

      #   @authorization_handler ||= Decidim::AuthorizationHandler.handler_for(handler_name,
      #                                                                        document_type:,
      #                                                                        document_number:,
      #                                                                        name:,
      #                                                                        first_surname:,
      #                                                                        second_surname:,
      #                                                                        date_of_birth:,
      #                                                                        postal_code:)
      # end

      # Private: The AuthorizationHandler name used to verify the user's
      # document number.
      #
      # Returns a String.
      # def handler_name
      #   candidacy.document_number_authorization_handler
      # end

      # def authorization_status
      #   return unless authorization

      #   Decidim::Verifications::Adapter.from_element(handler_name).authorize(authorization, {}, nil, nil)
      # end

      def encryptor
        @encryptor ||= DataEncryptor.new(secret: "personal user metadata")
      end
    end
  end
end
