# frozen_string_literal: true

namespace :valid_signador do
  desc "Enviar un XML al servicio de firma y guardarlo firmado"
  task :sign_xml => :environment do |_t, _args|
    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.oce do
        xml.avalcandidatura do
          xml.avalista do
            xml.nomb "Laura"
            xml.ape1 "Marbella"
            xml.ape2 "Martorell"
            xml.fnac "19941231"
            xml.tipoid "1"
            xml.id "00000000T"
          end
        end

        xml.candidatura do
          xml.elecciones "PARLAMENT DE CATALUNYA"
          xml.circumscripcion "Girona"
          xml.nombre "Agrupació d'electors per Girona"
        end
      end
    end

    # Generar XML sin espacios extra
    xml_document = builder.to_xml.strip

    puts "XML generado:"
    puts xml_document
    puts "\nEnviando XML para firma..."

    client = ValidSignador::Client.new
    init_response = client.init_process
    token = init_response["token"]
    @candidacy = Decidim::SignatureCollection::Candidacy.last

    client.start_sign_process(
      token: token,
      document: xml_document,
      options: {
        candidacy_id: @candidacy.id,
        user_id: nil,
        final_redirect_url: "/pepe",
        description: "Signatura electrònica de la candidatura '#{@candidacy.title}'",
        doc_name: "candidacy_#{@candidacy.id}_#{Time.current.to_i}.xml",
        hash_algorithm: "SHA-256"
      }
    )

    puts client.sign_url(token: token)
  end
end
