# frozen_string_literal: false

module Decidim
  module SignatureCollection
    class XmlBuilder
      include TranslatableAttributes

      def initialize(args = {})
        @candidacy = args.fetch(:candidacy)
        @name = args.fetch(:name)
        @first_surname = args.fetch(:first_surname)
        @second_surname = args.fetch(:second_surname)
        @document_type = args.fetch(:document_type)
        @document_number = args.fetch(:document_number)
        @date_of_birth = args.fetch(:date_of_birth)
      end

      def build
        candidacy_type = I18n.t("activerecord.attributes.decidim.signature_collection.candidacies_type.elections.#{@candidacy.type.elections}")
        date_of_birth = @date_of_birth.respond_to?(:iso8601) ? @date_of_birth.iso8601 : @date_of_birth.to_s
        date_of_birth = date_of_birth.to_s.split("T").first.delete("-")

        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <oce>
            <avalcandidatura>
              <avalista>
                <nomb>#{@name}</nomb>
                <ape1>#{@first_surname}</ape1>
                <ape2>#{@second_surname}</ape2>
                <fnac>#{date_of_birth.delete("-")}</fnac>
                <tipoid>#{@document_type}</tipoid>
                <id>#{@document_number}</id>
              </avalista>
            </avalcandidatura>
            <candidatura>
              <elecciones>#{candidacy_type}</elecciones>
              <circumscripcion>#{translated_attribute(@candidacy.scope.name)}</circumscripcion>
              <nombre>#{translated_attribute(@candidacy.title)}</nombre>
            </candidatura>
          </oce>
        XML
      end
    end
  end
end
