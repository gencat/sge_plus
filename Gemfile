# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

DECIDIM_VERSION= "0.30.3"

gem "decidim", DECIDIM_VERSION
gem "decidim-core", DECIDIM_VERSION
# gem "decidim-ai", DECIDIM_VERSION
# gem "decidim-conferences", DECIDIM_VERSION
# gem "decidim-design", DECIDIM_VERSION
gem "decidim-signature_collection", path: "./decidim-signature_collection"
# gem "decidim-templates", DECIDIM_VERSION

gem "decidim-cdtb", "~> 0.5.5"

gem "bootsnap", "~> 1.7"
gem "puma", ">= 6.3.1"

# https://github.com/hlascelles/figjam
gem "figjam", "2.0.0"

gem "deface"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "brakeman", "~> 7.0"
  gem "decidim-dev", DECIDIM_VERSION
  gem "net-imap", "~> 0.5.0"
  gem "net-pop", "~> 0.1.1"
  gem 'rubocop-rake', require: false
end

group :development do
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "web-console", "~> 4.2"
end
