# app/services/signador.rb
require 'net/http'
require 'openssl'
require 'base64'
require 'json'

module Signador
  class Client
    ALGORITHM_MAC = 'sha256'

    CONTEXT_INIT         = '/signador/initProcess'
    CONTEXT_STARTSIGN    = '/signador/startSignProcess'
    CONTEXT_SIGNADOR     = '/signador/?id='
    CONTEXT_GETSIGNATURE = '/signador/getSignature?identificador='

    def initialize
      @host           = ENV.fetch('SIGNADOR_DOMINI')        # ej: signador.aoc.cat
      @secret         = ENV.fetch('SIGNADOR_CLAU')          # clave HMAC
      @signature_mode = ENV.fetch('SIGNADOR_SIGNATURE_MODE').to_i
      @doc_type       = ENV.fetch('SIGNADOR_DOC_TYPE').to_i
      @keystore_type  = ENV.fetch('SIGNADOR_KEYSTORE_TYPE').to_i
      @origin         = ENV.fetch('SIGNADOR_URL_ENTORN')    # tu dominio
      @use_proxy      = ENV.fetch('SIGNADOR_USE_PROXY', 'false') == 'true'
      @proxy_host     = ENV['SIGNADOR_PROXY_HOST']
      @proxy_port     = ENV['SIGNADOR_PROXY_PORT']&.to_i
    end

    # ================= PUBLIC =================

    # Firma un XML y devuelve el contenido firmado (esperando que el usuario firme manualmente)
    def sign_xml(xml_content, redirect_url: '/firma', id: 1)
      xml_b64 = Base64.strict_encode64(xml_content)

      # 1️⃣ Init token
      token = init_token

      # 2️⃣ Start sign process
      start_token = start_sign_process(token, xml_b64, redirect_url)

      puts "Abre en el navegador para firmar: https://#{@host}#{CONTEXT_SIGNADOR}#{start_token}"
      puts "⚠️ Espera a que el usuario firme manualmente..."

      # 3️⃣ Polling simple para esperar a que se firme y recuperar XML
      signed_xml = nil
      20.times do
        begin
          signed_xml = get_signature(start_token)
          break if signed_xml
        rescue => _e
          sleep 3
        end
      end

      raise StandardError, "No se pudo recuperar el XML firmado" unless signed_xml

      signed_xml
    end

    # ================= INTERNAL =================

    def init_token

      response = execute_get(CONTEXT_INIT)
      if response['status'].casecmp('OK').zero?
        response['token']
      else
        raise StandardError, "InitProcess failed: #{response['message']}"
      end
    end

    def start_sign_process(token, xml_b64, redirect_url)
      body = {
        token: token,
        redirectUrl: redirect_url,
        applet_cfg: {
          keystore_type: @keystore_type,
          signature_mode: @signature_mode,
          doc_type: @doc_type,
          doc_name: "00000000T.xml",
          document_to_sign: xml_b64,
          multiple: false,
        },
      }

      response = execute_post(CONTEXT_STARTSIGN, body)
      if response['status'].casecmp('OK').zero?
        response['token']
      else
        raise StandardError, "StartSignProcess failed: #{response['message']}"
      end
    end

    def get_signature(token)
      response = execute_get(CONTEXT_GETSIGNATURE + token)
      case response['status']
      when 'OK'
        Base64.decode64(response['signResult'])
      when 'KO'
        raise StandardError, "Error recuperando firma: #{response['error']}"
      else
        nil
      end
    end

    # ================= HTTP =================

    def execute_get(path)
      uri = URI::HTTPS.build(host: @host, path: path)
      req = Net::HTTP::Get.new(uri.request_uri)
      add_headers(req)
      send_request(uri, req)
    end

    def execute_post(path, body)
      uri = URI::HTTPS.build(host: @host, path: path)
      req = Net::HTTP::Post.new(uri.request_uri)
      req['Content-Type'] = 'application/json'
      req['Origin'] = @origin
      req.body = body.to_json
      send_request(uri, req)
    end

    def send_request(uri, req)
      http =
        if @use_proxy
          Net::HTTP::Proxy(@proxy_host, @proxy_port).new(uri.host, uri.port)
        else
          Net::HTTP.new(uri.host, uri.port)
        end

      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Igual que NoopHostnameVerifier de Java

      puts "🔍 REQUEST DEBUG:"
      puts "  URL: https://#{uri.host}#{req.path}"
      puts "  Method: #{req.method}"
      puts "  Headers: #{req.to_hash.inspect}"
      puts "  Body: #{req.body.inspect}"
      
      res = http.request(req)
      puts "🔍 RESPONSE DEBUG:"
      puts "  Status: #{res.code} #{res.message}"
      puts "  Body: #{res.body}"

      unless res.is_a?(Net::HTTPSuccess)
        raise StandardError, "HTTP #{res.code}: #{res.message} - #{res.body}"
      end

      JSON.parse(res.body)
    end

    def add_headers(req)
      date = Time.now.in_time_zone('Europe/Madrid').strftime('%d/%m/%Y %H:%M')
      req['Authorization'] = create_codi_autenticacio(@origin, date)
      req['Origin']        = @origin
      req['Date']          = date
    end

    def create_codi_autenticacio(origin, formatted_date)
      data   = "#{origin}_#{formatted_date}"
      puts "🔍 HMAC DEBUG:"
      puts "  Origin: #{origin}"
      puts "  Date: #{formatted_date}"
      puts "  Data to sign: #{data}"
      puts "  Secret (first 10 chars): #{@secret[0..9]}..."
      digest = OpenSSL::HMAC.digest(ALGORITHM_MAC, @secret, data)
      auth = "SC #{Base64.strict_encode64(digest)}"
      puts "  Authorization: #{auth}"
      auth
    end
  end
end
