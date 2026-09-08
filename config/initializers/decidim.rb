# frozen_string_literal: true

Decidim.configure do |config|
  # The name of the application
  config.application_name = ENV["DECIDIM_APPLICATION_NAME"]

  # The email that will be used as sender in all emails from Decidim
  config.mailer_sender = ENV["DECIDIM_MAILER_SENDER"]

  # Sets the list of available locales for the whole application.
  #
  # When an organization is created through the System area, system admins will
  # be able to choose the available languages for that organization. That list
  # of languages will be equal or a subset of the list in this file.
  config.available_locales = ENV.fetch("DECIDIM_AVAILABLE_LOCALES", "ca,es,oc").split(",").map(&:to_sym)
  # Or block set it up manually and prevent ENV manipulation:
  # config.available_locales = %w(en ca es)

  # Sets the default locale for new organizations. When creating a new
  # organization from the System area, system admins will be able to overwrite
  # this value for that specific organization.
  config.default_locale = ENV.fetch("DECIDIM_DEFAULT_LOCALE", "en").to_sym

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

  # Map and Geocoder configuration
  #config.maps = {
  #  provider: :here,
  #  api_key: ENV["HERE_API_KEY"],
  #  static: { url: 'https://image.maps.hereapi.com/mia/v3/base/mc/overlay' }
  #}
  config.maps = {
    provider: :here,
    api_key: ENV["HERE_API_KEY"],
    static: false,
    dynamic: false,
    autocomplete: false,
    geocoding: false
  }

  # Workaround to enable SVG assets cors
  # config.cors_enabled = ENV["CORS_ENABLED"].present?

  # Max requests in a time period to prevent DoS attacks. Only applied on production.
  config.throttling_max_requests = ENV.fetch("DECIDIM_THROTTLING_MAX_REQUESTS", "100").to_i

  # Time window in which the throttling is applied.
  config.throttling_period = ENV.fetch("DECIDIM_THROTTLING_PERIOD", "1").to_i.minutes
end

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
Decidim.register_assets_path File.expand_path('app/packs', Rails.application.root)
