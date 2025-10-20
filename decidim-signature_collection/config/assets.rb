# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Webpacker.register_path("#{base_path}/app/packs")
Decidim::Webpacker.register_entrypoints(
  decidim_signature_collection: "#{base_path}/app/packs/entrypoints/decidim_signature_collection.js",
  decidim_signature_collection_admin: "#{base_path}/app/packs/entrypoints/decidim_signature_collection_admin.js"
)
