# ValidSignador - Client per a la signatura electrònica amb Signador (AOC)

Aquest client permet integrar el servei de signatura electrònica Signador del Consorci AOC per signar documents XML amb signatures XAdES-T enveloped (ETSI TS 101 903 amb timestamp qualificat).

## Configuració

### Variables d'entorn

Afegiu les següents variables al fitxer `config/application.yml`:

```yaml
# Signador configuration (Consorci AOC)
SIGNADOR_DOMAIN: "https://your-domain.cat"
SIGNADOR_API_KEY: "your_api_key_from_signador"
SIGNADOR_BASE_URL: "https://signador-pre.aoc.cat/signador"
SIGNADOR_LOGO_URL: "" # Optional: URL to your logo (max 300x100)
SIGNADOR_CALLBACK_PATH: "/valid_signador/callback"
```

### Entorns

- **Desenvolupament/Test**: `https://signador-pre.aoc.cat/signador`
- **Producció**: `https://signador.aoc.cat/signador`

### Registre amb el Consorci AOC

Abans d'utilitzar el servei, cal registrar-se amb el Consorci AOC proporcionant:

1. Domini des del qual es faran les peticions
2. Imatge del logo de l'aplicació (màx 300x100 píxels)
3. API key per l'autenticació HMAC SHA256

## Ús del Client

### 1. Inicialitzar el procés de signatura

```ruby
# En un controller, amb accés a la sessió
client = ValidSignador::Client.new(session: session)

# Obtenir un token del Signador
response = client.init_process
token = response["token"]
```

### 2. Preparar el document XML per signar

```ruby
# El vostre document XML
xml_document = "<xml>Document a signar</xml>"

# Opcions addicionals
options = {
  candidacy_id: 1,                    # ID de la candidatura
  user_id: current_user.id,           # ID de l'usuari
  final_redirect_url: "/success",     # On redirigir després de signar
  redirect_url: "/valid_signador/callback", # URL de callback
  description: "Signatura de candidatura", # Descripció
  doc_name: "candidacy.xml"           # Nom del document
}

# Iniciar el procés de signatura
response = client.start_sign_process(
  token: token,
  document: xml_document,
  options: options
)
```

### 3. Redirigir l'usuari a signar

```ruby
# Obtenir la URL de signatura
sign_url = client.sign_url(token: token)

# Redirigir l'usuari
redirect_to sign_url
```

### 4. Processar la resposta (CallbacksController)

El `ValidSignador::CallbacksController` gestiona automàticament la resposta del Signador:

- Valida el token
- Recupera l'estat del procés de la sessió
- Descodifica el document signat
- Redirigeix a la URL original amb missatge d'èxit o error

## Flux complet d'exemple

```ruby
class CandidaciesController < ApplicationController
  def sign_document
    # 1. Preparar el document XML
    xml_document = generate_candidacy_xml(@candidacy)
    
    # 2. Inicialitzar el client
    client = ValidSignador::Client.new(session: session)
    
    # 3. Obtenir token
    init_response = client.init_process
    token = init_response["token"]
    
    # 4. Iniciar el procés de signatura
    client.start_sign_process(
      token: token,
      document: xml_document,
      options: {
        candidacy_id: @candidacy.id,
        user_id: current_user.id,
        final_redirect_url: candidacy_path(@candidacy),
        description: "Signatura de candidatura #{@candidacy.title}",
        doc_name: "candidacy_#{@candidacy.id}.xml"
      }
    )
    
    # 5. Redirigir l'usuari a signar
    redirect_to client.sign_url(token: token)
    
  rescue ValidSignador::Error => e
    Rails.logger.error("Error en el procés de signatura: #{e.message}")
    redirect_to @candidacy, alert: "Error inicialitzant la signatura"
  end
end
```

## Característiques tècniques

### Tipus de signatura

- **Mode**: XAdES-T enveloped (mode 12)
- **Estàndard**: ETSI TS 101 903
- **Timestamp**: Qualificat (inclòs per defecte)
- **Document**: Enviat complet en base64 (`doc_type: "4"`)
- **Hash Algorithm**: SHA-256 (per defecte)

### Autenticació

- **Mètode**: HMAC SHA256
- **Headers**:
  - `Authorization: SC <hmac_base64>`
  - `Origin: <domain>`
  - `Date: dd/MM/yyyy HH:mm`

### Gestió d'estat

L'estat del procés de signatura s'emmagatzema temporalment a la sessió:

```ruby
session[:valid_signador_process] = {
  token: "unique-token",
  candidacy_id: 1,
  document_original: "<xml>...</xml>",
  timestamp_inici: "2025-12-17T10:30:00Z",
  user_id: 2,
  redirect_url: "/candidacies/1"
}
```

## Gestió d'errors

El client defineix les següents excepcions:

- `ValidSignador::Error` - Error base
- `ValidSignador::AuthenticationError` - Error d'autenticació
- `ValidSignador::ApiError` - Error de l'API del Signador
- `ValidSignador::InvalidResponseError` - Resposta invàlida
- `ValidSignador::ConfigurationError` - Configuració incorrecta
- `ValidSignador::TokenExpiredError` - Token expirat

```ruby
begin
  client.init_process
rescue ValidSignador::AuthenticationError => e
  # Problema d'autenticació amb l'API
rescue ValidSignador::ApiError => e
  # Error del servei Signador
rescue ValidSignador::ConfigurationError => e
  # Variables d'entorn incorrectes
end
```

## Tests

Executar els tests:

```bash
# Tots els tests de ValidSignador
bundle exec rspec spec/services/valid_signador/
bundle exec rspec spec/controllers/valid_signador/

# Test específic
bundle exec rspec spec/services/valid_signador/client_spec.rb
```

## Limitacions i consideracions

1. **Timeout del token**: Els tokens del Signador expiren després d'aproximadament 15 minuts
2. **Disponibilitat de signatures**: Les signatures recuperades només estan disponibles durant 15 dies
3. **Sincronització horària**: El servidor ha de tenir l'hora sincronitzada (±1 hora respecte al servidor Signador)
4. **CORS**: El domini ha d'estar registrat al Consorci AOC per permetre les peticions

## Suport

Per problemes amb el servei Signador, contacteu amb el Consorci AOC:
- Web: https://www.aoc.cat
- Documentació: https://github.com/ConsorciAOC/signador
