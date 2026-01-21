# frozen_string_literal: true

# Exemple d'ús del client ValidSignador per signar documents XML de candidatures
#
# Aquest fitxer mostra com integrar la signatura electrònica en el flux
# de creació/gestió de candidatures utilitzant el servei Signador del Consorci AOC.

```ruby
module Decidim
  module SignatureCollection
    # Exemple de controller que utilitza ValidSignador per signar documents XML
    class CandidacySignaturesExampleController < ApplicationController
      before_action :authenticate_user!
      before_action :load_candidacy

      # GET /candidacies/:candidacy_id/sign_xml
      # Inicia el procés de signatura d'un document XML de candidatura
      def new
        # Renderitzar vista amb botó "Signar amb certificat digital"
      end

      # POST /candidacies/:candidacy_id/sign_xml
      # Crea el document XML i inicia el procés de signatura
      def create
        # 1. Generar el document XML de la candidatura
        xml_document = generate_candidacy_xml

        # 2. Inicialitzar el client amb la sessió actual
        client = ValidSignador::Client.new(session: session)

        # 3. Obtenir un token del servei Signador
        init_response = client.init_process
        token = init_response["token"]

        # 4. Configurar i iniciar el procés de signatura
        client.start_sign_process(
          token: token,
          document: xml_document,
          options: {
            candidacy_id: @candidacy.id,
            user_id: current_user.id,
            final_redirect_url: candidacy_signed_path(@candidacy),
            description: "Signatura electrònica de la candidatura '#{@candidacy.title}'",
            doc_name: "candidacy_#{@candidacy.id}_#{Time.current.to_i}.xml",
            hash_algorithm: "SHA-256" # Opcional, per defecte ja és SHA-256
          }
        )

        # 5. Redirigir l'usuari al servei Signador per signar
        redirect_to client.sign_url(token: token), allow_other_host: true
      rescue ValidSignador::ConfigurationError => e
        Rails.logger.error("Error de configuració ValidSignador: #{e.message}")
        redirect_to @candidacy, alert: "Error de configuració del servei de signatura"
      rescue ValidSignador::AuthenticationError => e
        Rails.logger.error("Error d'autenticació ValidSignador: #{e.message}")
        redirect_to @candidacy, alert: "Error d'autenticació amb el servei de signatura"
      rescue ValidSignador::ApiError => e
        Rails.logger.error("Error API ValidSignador: #{e.message}")
        redirect_to @candidacy, alert: "Error comunicant amb el servei de signatura"
      rescue StandardError => e
        Rails.logger.error("Error inesperat en signatura: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        redirect_to @candidacy, alert: "Error inicialitzant el procés de signatura"
      end

      # GET /candidacies/:candidacy_id/signed
      # Pàgina de confirmació després de signar (redirecció des del callback)
      def signed
        # L'usuari arriba aquí després que ValidSignador::CallbacksController
        # processi el document signat
        flash.now[:notice] = "El document ha estat signat correctament"
      end

      private

      def load_candidacy
        @candidacy = Decidim::SignatureCollection::Candidacy.find(params[:candidacy_id])
      end

      def generate_candidacy_xml
        # Exemple de generació d'un document XML amb les dades de la candidatura
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.candidacy(xmlns: "http://example.cat/candidacy") do
            xml.id @candidacy.id
            xml.title @candidacy.title["ca"]
            xml.description @candidacy.description["ca"]
            xml.author do
              xml.name @candidacy.author.name
              xml.email @candidacy.author.email
            end
            xml.created_at @candidacy.created_at.iso8601
            xml.signature_type @candidacy.signature_type
            xml.scope do
              xml.id @candidacy.scope&.id
              xml.name @candidacy.scope&.name&.dig("ca")
            end
            xml.metadata do
              xml.signed_by current_user.name
              xml.signed_at Time.current.iso8601
            end
          end
        end

        builder.to_xml
      end
    end
  end
end

# Exemple d'ús en una tasca Rake o servei per processar signatures massivament
module Decidim
  module SignatureCollection
    class BulkSignatureService
      def initialize(candidacies, user)
        @candidacies = candidacies
        @user = user
      end

      def call
        @candidacies.each do |candidacy|
          sign_candidacy(candidacy)
        end
      end

      private

      def sign_candidacy(candidacy)
        # Nota: En un procés batch sense sessió web, caldria
        # implementar un mecanisme diferent d'emmagatzematge de l'estat
        # (per exemple, una taula a la base de dades)

        xml_document = generate_candidacy_xml(candidacy)

        # Crear un hash per emmagatzemar l'estat temporalment
        temp_session = {}
        client = ValidSignador::Client.new(session: temp_session)

        init_response = client.init_process
        token = init_response["token"]

        client.start_sign_process(
          token: token,
          document: xml_document,
          options: {
            candidacy_id: candidacy.id,
            user_id: @user.id,
            description: "Signatura batch de candidatura #{candidacy.id}"
          }
        )

        # Aquí caldria implementar un mecanisme per emmagatzemar
        # el token i l'estat a la base de dades
        store_signature_process(candidacy, token, temp_session[:valid_signador_process])
      rescue ValidSignador::Error => e
        Rails.logger.error("Error signant candidatura #{candidacy.id}: #{e.message}")
      end

      def generate_candidacy_xml(candidacy)
        # Similar a l'exemple anterior
        # ...
      end

      def store_signature_process(candidacy, token, process_state)
        # Exemple: crear un registre a la base de dades
        # SignatureProcess.create!(
        #   candidacy: candidacy,
        #   token: token,
        #   process_state: process_state.to_json,
        #   status: :pending
        # )
      end
    end
  end
end

# Exemple de com consultar l'estat d'una signatura
module Decidim
  module SignatureCollection
    class CheckSignatureStatusService
      def initialize(token)
        @token = token
        @client = ValidSignador::Client.new
      end

      def call
        response = @client.get_signature(token: @token)

        if response["status"] == "OK"
          signed_document = decode_signature_result(response["signResult"])
          save_signed_document(signed_document)
          { status: :success, document: signed_document }
        else
          { status: :error, message: response["error"] }
        end
      rescue ValidSignador::Error => e
        Rails.logger.error("Error consultant signatura: #{e.message}")
        { status: :error, message: e.message }
      end

      private

      def decode_signature_result(sign_result)
        if sign_result.start_with?("http://", "https://")
          # Si és una URL, caldria fer una petició HTTP per obtenir el document
          fetch_from_url(sign_result)
        else
          # Si és base64, decodificar
          Base64.decode64(sign_result)
        end
      end

      def fetch_from_url(url)
        # Implementar lògica per obtenir el document de la URL
      end

      def save_signed_document(document)
        # Implementar lògica per guardar el document signat
        # (ActiveStorage, filesystem, etc.)
      end
    end
  end
end
```ruby
