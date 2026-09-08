# frozen_string_literal: true

Decidim.configure do |config|
  # The name of the application
  config.application_name = ENV.fetch("DECIDIM_APPLICATION_NAME", nil)

  # The email that will be used as sender in all emails from Decidim
  config.mailer_sender = ENV.fetch("DECIDIM_MAILER_SENDER", nil)

  # Sets the list of available locales for the whole application.
  #
  # When an organization is created through the System area, system admins will
  # be able to choose the available languages for that organization. That list
  # of languages will be equal or a subset of the list in this file.
  config.available_locales = [:ca, :es, :oc]
  # Or block set it up manually and prevent ENV manipulation:
  # config.available_locales = %w(en ca es)

  # Sets the default locale for new organizations. When creating a new
  # organization from the System area, system admins will be able to overwrite
  # this value for that specific organization.
  config.default_locale = ENV.fetch("DECIDIM_DEFAULT_LOCALE", "ca").to_sym

  # Restrict access to the system part with an authorized ip list.
  # You can use a single ip like ("1.2.3.4"), or an ip subnet like ("1.2.3.4/24")
  # You may specify multiple ip in an array ["1.2.3.4", "1.2.3.4/24"]
  config.system_accesslist_ips = ENV["DECIDIM_SYSTEM_ACCESSLIST_IPS"] if ENV["DECIDIM_SYSTEM_ACCESSLIST_IPS"].present?

  # Defines a list of custom content processors. They are used to parse and
  # render specific tags inside some user-provided content. Check the docs for
  # more info.
  # config.content_processors = []

  # Whether SSL should be enabled or not.
  # if this var is not defined, it is decided automatically per-rails-environment
  config.force_ssl = ENV["DECIDIM_FORCE_SSL"].present? unless ENV["DECIDIM_FORCE_SSL"] == "auto"
  # or set it up manually and prevent any ENV manipulation:
  # config.force_ssl = true

  # Enable the service worker. By default is disabled in development and enabled in the rest of environments
  config.service_worker_enabled = ENV["DECIDIM_SERVICE_WORKER_ENABLED"].present?

  # Sets the list of static pages' slugs that can include content blocks.
  # By default is only enabled in the terms-of-service static page to allow a summary to be added and include
  # sections with a two-pane view
  config.page_blocks = ENV.fetch("DECIDIM_PAGE_BLOCKS", "terms-of-service").split(",").map(&:strip)

  # Map and Geocoder configuration
  #
  # See Decidim docs at https://docs.decidim.org/en/develop/services/maps.html
  # for more information about how it works and how to set it up.
  #
  # == HERE Maps ==
  # config.maps = {
  #   provider: :here,
  #   api_key: Rails.application.secrets.maps[:api_key],
  #   static: { url: "https://image.maps.hereapi.com/mia/v3/base/mc/overlay" }
  # }
  #
  # == OpenStreetMap (OSM) services ==
  # To use the OSM map service providers, you will need a service provider for
  # the following map servers or host all of them yourself:
  # - A tile server for the dynamic maps
  #   (https://wiki.openstreetmap.org/wiki/Tile_servers)
  # - A Nominatim geocoding server for the geocoding functionality
  #   (https://wiki.openstreetmap.org/wiki/Nominatim)
  # - A static map server for static map images
  #   (https://github.com/jperelli/osm-static-maps)
  #
  # When used, please read carefully the terms of service for your service
  # provider.
  #
  # config.maps = {
  #   provider: :osm,
  #   api_key: Rails.application.secrets.maps[:api_key],
  #   dynamic: {
  #     tile_layer: {
  #       url: "https://tiles.example.org/{z}/{x}/{y}.png?key={apiKey}&{foo}",
  #       api_key: true,
  #       foo: "bar=baz",
  #       attribution: %(
  #         <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap</a> contributors
  #       ).strip
  #       # Translatable attribution:
  #       # attribution: -> { I18n.t("tile_layer_attribution") }
  #     }
  #   },
  #   static: { url: "https://staticmap.example.org/" },
  #   geocoding: { host: "nominatim.example.org", use_https: true }
  # }
  #
  # == Combination (OpenStreetMap default + HERE Maps dynamic map tiles) ==
  # config.maps = {
  #   provider: :osm,
  #   api_key: Rails.application.secrets.maps[:api_key],
  #   dynamic: {
  #     provider: :here,
  #     api_key: Rails.application.secrets.maps[:here_api_key]
  #   },
  #   static: { url: "https://staticmap.example.org/" },
  #   geocoding: { host: "nominatim.example.org", use_https: true }
  # }

  # Geocoder configurations if you want to customize the default geocoding
  # settings. The maps configuration will manage which geocoding service to use,
  # so that does not need any additional configuration here. Use this only for
  # the global geocoder preferences.
  # config.geocoder = {
  #   # geocoding service request timeout, in seconds (default 3):
  #   timeout: 5,
  #   # set default units to kilometers:
  #   units: :km,
  #   # caching (see https://github.com/alexreisner/geocoder#caching for details):
  #   cache: Redis.new,
  #   cache_prefix: "..."
  # }
  if ENV["DECIDIM_MAPS_STATIC_PROVIDER"].present?
    static_provider = ENV["DECIDIM_MAPS_STATIC_PROVIDER"]
    dynamic_provider = ENV.fetch("DECIDIM_MAPS_DYNAMIC_PROVIDER", nil)
    dynamic_url = ENV.fetch("DECIDIM_MAPS_DYNAMIC_URL", nil)
    static_url = ENV.fetch("DECIDIM_MAPS_STATIC_URL", nil)
    static_url = "https://image.maps.hereapi.com/mia/v3/base/mc/overlay" if static_provider == "here"
    config.maps = {
      provider: static_provider,
      api_key: ENV.fetch("DECIDIM_MAPS_STATIC_API_KEY", nil),
      static: { url: static_url },
      dynamic: {
        provider: dynamic_provider,
        api_key: ENV.fetch("DECIDIM_MAPS_DYNAMIC_API_KEY", nil)
      }
    }
    config.maps[:geocoding] = { host: ENV["DECIDIM_MAPS_GEOCODING_HOST"], use_https: true } if ENV["DECIDIM_MAPS_GEOCODING_HOST"].present?
    config.maps[:dynamic][:tile_layer] = {}
    config.maps[:dynamic][:tile_layer][:url] = dynamic_url if dynamic_url
    config.maps[:dynamic][:tile_layer][:attribution] = ENV["DECIDIM_MAPS_ATTRIBUTION"] if ENV["DECIDIM_MAPS_ATTRIBUTION"].present?
    if ENV["DECIDIM_MAPS_EXTRA_VARS"].present?
      vars = URI.decode_www_form(ENV["DECIDIM_MAPS_EXTRA_VARS"])
      vars.each do |key, value|
        # perform a naive type conversion
        config.maps[:dynamic][:tile_layer][key] = case value
                                                  when /^true$|^false$/i
                                                    value.downcase == "true"
                                                  when /\A[-+]?\d+\z/
                                                    value.to_i
                                                  else
                                                    value
                                                  end
      end
    end
  end

  # Custom resource reference generator method. Check the docs for more info.
  # config.reference_generator = lambda do |resource, component|
  #   # Implement your custom method to generate resources references
  #   "1234-#{resource.id}"
  # end

  # Currency unit
  config.currency_unit = ENV["DECIDIM_CURRENCY_UNIT"] if ENV["DECIDIM_CURRENCY_UNIT"].present?

  # Workaround to enable SVG assets cors
  config.cors_enabled = ENV["DECIDIM_CORS_ENABLED"].present?

  # Defines the quality of image uploads after processing. Image uploads are
  # processed by Decidim, this value helps reduce the size of the files.
  config.image_uploader_quality = ENV["DECIDIM_IMAGE_UPLOADER_QUALITY"].to_i

  config.maximum_attachment_size = ENV["DECIDIM_MAXIMUM_ATTACHMENT_SIZE"].to_i.megabytes
  config.maximum_avatar_size = ENV["DECIDIM_MAXIMUM_AVATAR_SIZE"].to_i.megabytes

  # The number of reports which a resource can receive before hiding it
  config.max_reports_before_hiding = ENV["DECIDIM_MAX_REPORTS_BEFORE_HIDING"].to_i

  # Custom HTML Header snippets
  #
  # The most common use is to integrate third-party services that require some
  # extra JavaScript or CSS. Also, you can use it to add extra meta tags to the
  # HTML. Note that this will only be rendered in public pages, not in the admin
  # section.
  #
  # Before enabling this you should ensure that any tracking that might be done
  # is in accordance with the rules and regulations that apply to your
  # environment and usage scenarios. This component also comes with the risk
  # that an organization's administrator injects malicious scripts to spy on or
  # take over user accounts.
  #
  config.enable_html_header_snippets = ENV["DECIDIM_ENABLE_HTML_HEADER_SNIPPETS"].present?

  # Allow organizations admins to track newsletter links.
  config.track_newsletter_links = ENV["DECIDIM_TRACK_NEWSLETTER_LINKS"].present? unless ENV["DECIDIM_TRACK_NEWSLETTER_LINKS"] == "auto"

  # Amount of time that the download your data files will be available in the server.
  config.download_your_data_expiry_time = ENV["DECIDIM_DOWNLOAD_YOUR_DATA_EXPIRY_TIME"].to_i.days

  # Max requests in a time period to prevent DoS attacks. Only applied on production.
  config.throttling_max_requests = ENV["DECIDIM_THROTTLING_MAX_REQUESTS"].to_i

  # Time window in which the throttling is applied.
  config.throttling_period = ENV["DECIDIM_THROTTLING_PERIOD"].to_i.minutes

  # Time window were users can access the website even if their email is not confirmed.
  config.unconfirmed_access_for = ENV["DECIDIM_UNCONFIRMED_ACCESS_FOR"].to_i.days

  # A base path for the uploads. If set, make sure it ends in a slash.
  # Uploads will be set to `<base_path>/uploads/`. This can be useful if you
  # want to use the same uploads place for both staging and production
  # environments, but in different folders.
  #
  # If not set, it will be ignored.
  config.base_uploads_path = ENV["DECIDIM_BASE_UPLOADS_PATH"] if ENV["DECIDIM_BASE_UPLOADS_PATH"].present?

  # SMS gateway configuration
  #
  # If you want to verify your users by sending a verification code via
  # SMS you need to provide a SMS gateway service class.
  #
  # An example class would be something like:
  #
  # class MySMSGatewayService
  #   attr_reader :mobile_phone_number, :code
  #
  #   def initialize(mobile_phone_number, code)
  #     @mobile_phone_number = mobile_phone_number
  #     @code = code
  #   end
  #
  #   def deliver_code
  #     # Actual code to deliver the code
  #     true
  #   end
  # end
  #
  # config.sms_gateway_service = "MySMSGatewayService"

  # Timestamp service configuration
  #
  # Provide a class to generate a timestamp for a document. The instances of
  # this class are initialized with a hash containing the :document key with
  # the document to be timestamped as value. The instances respond to a
  # timestamp public method with the timestamp
  #
  # An example class would be something like:
  #
  # class MyTimestampService
  #   attr_accessor :document
  #
  #   def initialize(args = {})
  #     @document = args.fetch(:document)
  #   end
  #
  #   def timestamp
  #     # Code to generate timestamp
  #     "My timestamp"
  #   end
  # end
  #
  #
  # config.timestamp_service = "MyTimestampService"

  # PDF signature service configuration
  #
  # Provide a class to process a pdf and return the document including a
  # digital signature. The instances of this class are initialized with a hash
  # containing the :pdf key with the pdf file content as value. The instances
  # respond to a signed_pdf method containing the pdf with the signature
  #
  # An example class would be something like:
  #
  # class MyPDFSignatureService
  #   attr_accessor :pdf
  #
  #   def initialize(args = {})
  #     @pdf = args.fetch(:pdf)
  #   end
  #
  #   def signed_pdf
  #     # Code to return the pdf signed
  #   end
  # end
  #
  # config.pdf_signature_service = "MyPDFSignatureService"

  # Etherpad configuration
  #
  # Only needed if you want to have Etherpad integration with Decidim. See
  # Decidim docs at https://docs.decidim.org/en/services/etherpad/ in order to set it up.
  #
  if ENV["DECIDIM_ETHERPAD_SERVER"].present?
    config.etherpad = {
      server: ENV["DECIDIM_ETHERPAD_SERVER"],
      api_key: ENV.fetch("DECIDIM_ETHERPAD_API_KEY", nil),
      api_version: ENV.fetch("DECIDIM_ETHERPAD_API_VERSION", nil)
    }
  end

  # Sets Decidim::Exporters::CSV's default column separator
  config.default_csv_col_sep = ENV["DECIDIM_DEFAULT_CSV_COL_SEP"] if ENV["DECIDIM_DEFAULT_CSV_COL_SEP"].present?

  # The list of roles a user can have, not considering the space-specific roles.
  # config.user_roles = %w(admin user_manager)

  # The list of visibility options for amendments. An Array of Strings that
  # serve both as locale keys and values to construct the input collection in
  # Decidim::Amendment::VisibilityStepSetting::options.
  #
  # This collection is used in Decidim::Admin::SettingsHelper to generate a
  # radio buttons collection input field form for a Decidim::Component
  # step setting :amendments_visibility.
  # config.amendments_visibility_options = %w(all participants)

  # Machine Translation Configuration
  #
  # See Decidim docs at https://docs.decidim.org/en/develop/machine_translations/
  # for more information about how it works and how to set it up.
  #
  # Enable machine translations
  config.enable_machine_translations = false
  #
  # If you want to enable machine translation you can create your own service
  # to interact with third party service to translate the user content.
  #
  # If you still want to use "Decidim::Dev::DummyTranslator" as translator placeholder,
  # add the following line at the beginning of this file:
  # require "decidim/dev/dummy_translator"
  #
  # An example class would be something like:
  #
  # class MyTranslationService
  #   attr_reader :text, :original_locale, :target_locale
  #
  #   def initialize(text, original_locale, target_locale)
  #     @text = text
  #     @original_locale = original_locale
  #     @target_locale = target_locale
  #   end
  #
  #   def translate
  #     # Actual code to translate the text
  #   end
  # end
  #
  # config.machine_translation_service = "MyTranslationService"

  # Defines the social networking services used for social sharing
  config.social_share_services = ENV["DECIDIM_SOCIAL_SHARE_SERVICES"] if ENV["DECIDIM_SOCIAL_SHARE_SERVICES"].present?

  # Defines the name of the cookie used to check if the user allows Decidim to
  # set cookies.
  config.consent_cookie_name = ENV["DECIDIM_CONSENT_COOKIE_NAME"] if ENV["DECIDIM_CONSENT_COOKIE_NAME"].present?

  # Defines data consent categories and the data stored in each category.
  # config.consent_categories = [
  #   {
  #     slug: "essential",
  #     mandatory: true,
  #     items: [
  #       {
  #         type: "cookie",
  #         name: "_session_id"
  #       },
  #       {
  #         type: "cookie",
  #         name: Decidim.consent_cookie_name
  #       }
  #     ]
  #   },
  #   {
  #     slug: "preferences",
  #     mandatory: false
  #   },
  #   {
  #     slug: "analytics",
  #     mandatory: false
  #   },
  #   {
  #     slug: "marketing",
  #     mandatory: false
  #   }
  # ]

  # Defines additional content security policies following the structure
  # Read more: https://docs.decidim.org/en/develop/configure/initializer#_content_security_policy
  config.content_security_policies_extra = {}

  # Admin admin password configurations
  ENV["DECIDIM_ADMIN_PASSWORD_STRONG"].tap do |strong_pw|
    # When the strong password is not configured, default to true
    config.admin_password_strong = strong_pw.nil? ? true : strong_pw.present?
  end
  config.admin_password_expiration_days = ENV["DECIDIM_ADMIN_PASSWORD_EXPIRATION_DAYS"].presence || 90
  config.admin_password_min_length = ENV["DECIDIM_ADMIN_PASSWORD_MIN_LENGTH"].presence || 15
  config.admin_password_repetition_times = ENV["DECIDIM_ADMIN_PASSWORD_REPETITION_TIMES"].presence || 5

  # Additional optional configurations (see decidim-core/lib/decidim/core.rb)
  config.cache_key_separator = ENV["DECIDIM_CACHE_KEY_SEPARATOR"] if ENV["DECIDIM_CACHE_KEY_SEPARATOR"].present?
  config.cache_expiry_time = ENV["DECIDIM_CACHE_EXPIRY_TIME"].to_i.minutes if ENV["DECIDIM_CACHE_EXPIRY_TIME"].present?
  config.stats_cache_expiry_time = ENV["DECIDIM_STATS_CACHE_EXPIRY_TIME"].to_i.minutes if ENV["DECIDIM_STATS_CACHE_EXPIRY_TIME"].present?
  config.expire_session_after = ENV["DECIDIM_EXPIRE_SESSION_AFTER"].to_i.minutes if ENV["DECIDIM_EXPIRE_SESSION_AFTER"].present?
  config.enable_remember_me = ENV["DECIDIM_ENABLE_REMEMBER_ME"].present? unless ENV["DECIDIM_ENABLE_REMEMBER_ME"] == "auto"
  config.session_timeout_interval = ENV["DECIDIM_SESSION_TIMEOUT_INTERVAL"].to_i.seconds if ENV["DECIDIM_SESSION_TIMEOUT_INTERVAL"].present?
  config.follow_http_x_forwarded_host = ENV["DECIDIM_FOLLOW_HTTP_X_FORWARDED_HOST"].present?
  config.maximum_conversation_message_length = ENV["DECIDIM_MAXIMUM_CONVERSATION_MESSAGE_LENGTH"].to_i
  config.password_similarity_length = ENV["DECIDIM_PASSWORD_SIMILARITY_LENGTH"] if ENV["DECIDIM_PASSWORD_SIMILARITY_LENGTH"].present?
  config.denied_passwords = ENV["DECIDIM_DENIED_PASSWORDS"] if ENV["DECIDIM_DENIED_PASSWORDS"].present?
  config.allow_open_redirects = ENV["DECIDIM_ALLOW_OPEN_REDIRECTS"] if ENV["DECIDIM_ALLOW_OPEN_REDIRECTS"].present?
  config.enable_etiquette_validator = ENV["DECIDIM_ENABLE_ETIQUETTE_VALIDATOR"] if ENV["DECIDIM_ENABLE_ETIQUETTE_VALIDATOR"].present?
end

if Decidim.module_installed? :api
  Decidim::Api.configure do |config|
    config.schema_max_per_page = ENV["DECIDIM_API_SCHEMA_MAX_PER_PAGE"].presence || 50
    config.schema_max_complexity = ENV["DECIDIM_API_SCHEMA_MAX_COMPLEXITY"].presence || 5000
    config.schema_max_depth = ENV["DECIDIM_API_SCHEMA_MAX_DEPTH"].presence || 15
  end
end

if Decidim.module_installed? :proposals
  Decidim::Proposals.configure do |config|
    config.participatory_space_highlighted_proposals_limit = ENV["DECIDIM_PROPOSALS_PARTICIPATORY_SPACE_HIGHLIGHTED_PROPOSALS_LIMIT"].presence || 4
    config.process_group_highlighted_proposals_limit = ENV["DECIDIM_PROPOSALS_PROCESS_GROUP_HIGHLIGHTED_PROPOSALS_LIMIT"].presence || 3
  end
end

if Decidim.module_installed? :meetings
  Decidim::Meetings.configure do |config|
    config.upcoming_meeting_notification = ENV["DECIDIM_MEETINGS_UPCOMING_MEETING_NOTIFICATION"].to_i.days
    config.embeddable_services = ENV["DECIDIM_MEETINGS_EMBEDDABLE_SERVICES"] if ENV["DECIDIM_MEETINGS_EMBEDDABLE_SERVICES"].present?
    config.enable_proposal_linking = ENV["DECIDIM_MEETINGS_ENABLE_PROPOSAL_LINKING"].present? unless ENV["DECIDIM_MEETINGS_ENABLE_PROPOSAL_LINKING"] == "auto"
  end
end

if Decidim.module_installed? :budgets
  Decidim::Budgets.configure do |config|
    config.enable_proposal_linking = ENV["DECIDIM_BUDGETS_ENABLE_PROPOSAL_LINKING"].present? unless ENV["DECIDIM_BUDGETS_ENABLE_PROPOSAL_LINKING"] == "auto"
  end
end

# if Decidim.module_installed? :accountability
#   Decidim::Accountability.configure do |config|
#     unless ENV["DECIDIM_ACCOUNTABILITY_ENABLE_PROPOSAL_LINKING"] == "auto"
#       config.enable_proposal_linking = ENV["DECIDIM_ACCOUNTABILITY_ENABLE_PROPOSAL_LINKING"].present?
#     end
#   end
# end

if Decidim.module_installed? :signature_collection
  Decidim::SignatureCollection.configure do |config|
    config.minimum_committee_members = ENV["DECIDIM_SIGNATURE_COLLECTION_MINIMUM_COMMITTEE_MEMBERS"].presence || 0
    config.default_components = ENV["DECIDIM_SIGNATURE_COLLECTION_DEFAULT_COMPONENTS"] if ENV["DECIDIM_SIGNATURE_COLLECTION_DEFAULT_COMPONENTS"].present?
    config.first_notification_percentage = ENV["DECIDIM_SIGNATURE_COLLECTION_FIRST_NOTIFICATION_PERCENTAGE"].presence || 33
    config.second_notification_percentage = ENV["DECIDIM_SIGNATURE_COLLECTION_SECOND_NOTIFICATION_PERCENTAGE"].presence || 66
    config.stats_cache_expiration_time = ENV["DECIDIM_SIGNATURE_COLLECTION_STATS_CACHE_EXPIRATION_TIME"].to_i.minutes
    config.max_time_in_validating_state = ENV["DECIDIM_SIGNATURE_COLLECTION_MAX_TIME_IN_VALIDATING_STATE"].to_i.days
    config.print_enabled = ENV["DECIDIM_SIGNATURE_COLLECTION_PRINT_ENABLED"].present? unless ENV["DECIDIM_SIGNATURE_COLLECTION_PRINT_ENABLED"] == "auto"
    config.do_not_require_authorization = ENV["DECIDIM_SIGNATURE_COLLECTION_DO_NOT_REQUIRE_AUTHORIZATION"].present?
  end
end

if Decidim.module_installed? :signature_collection
  Decidim::SignatureCollection.configure do |config|
    config.minimum_committee_members = ENV["DECIDIM_CANDIDACIES_MINIMUM_COMMITTEE_MEMBERS"].presence || 0
    config.default_components = ENV["DECIDIM_CANDIDACIES_DEFAULT_COMPONENTS"] if ENV["DECIDIM_CANDIDACIES_DEFAULT_COMPONENTS"].present?
    config.first_notification_percentage = ENV["DECIDIM_CANDIDACIES_FIRST_NOTIFICATION_PERCENTAGE"].presence || 33
    config.second_notification_percentage = ENV["DECIDIM_CANDIDACIES_SECOND_NOTIFICATION_PERCENTAGE"].presence || 66
    config.stats_cache_expiration_time = ENV["DECIDIM_CANDIDACIES_STATS_CACHE_EXPIRATION_TIME"].to_i.minutes
    config.max_time_in_validating_state = ENV["DECIDIM_CANDIDACIES_MAX_TIME_IN_VALIDATING_STATE"].to_i.days
    config.print_enabled = ENV["DECIDIM_CANDIDACIES_PRINT_ENABLED"].present? unless ENV["DECIDIM_CANDIDACIES_PRINT_ENABLED"] == "auto"
    config.do_not_require_authorization = ENV["DECIDIM_CANDIDACIES_DO_NOT_REQUIRE_AUTHORIZATION"].present?
  end
end

Rails.application.config.i18n.available_locales = Decidim.available_locales
Rails.application.config.i18n.default_locale = Decidim.default_locale

# Inform Decidim about the assets folder
Decidim.register_assets_path File.expand_path("app/packs", Rails.application.root)
