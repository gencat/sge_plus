# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/signature_collection/version"

Gem::Specification.new do |s|
  s.version = Decidim::SignatureCollection.version
  s.authors = ["Rubén Gonzalez", "Laura Jaime", "Oliver Valls"]
  s.license = "AGPL-3.0-or-later"
  s.homepage = "https://decidim.org"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/gencat/sge_plus/issues",
    "documentation_uri" => "https://github.com/gencat/sge_plus",
    "homepage_uri" => "https://github.com/gencat/sge_plus",
    "source_code_uri" => "https://github.com/gencat/sge_plus"
  }
  s.required_ruby_version = "~> 3.3.4"

  s.name = "decidim-signature_collection"
  s.summary = "Decidim signature collection module"
  s.description = "Module that helps groups collecting signatures mainly as candidacies for elections."

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").select do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w(app/ config/ db/ lib/ Rakefile README.md))
    end
  end

  s.add_dependency "decidim-admin", "~> #{Decidim::SignatureCollection.min_decidim_version}"
  s.add_dependency "decidim-comments", "~> #{Decidim::SignatureCollection.min_decidim_version}"
  s.add_dependency "decidim-core", "~> #{Decidim::SignatureCollection.min_decidim_version}"
  s.add_dependency "decidim-verifications", "~> #{Decidim::SignatureCollection.min_decidim_version}"
end
