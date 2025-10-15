# frozen_string_literal: true

namespace :decidim_candidacies do
  namespace :upgrade do
    desc "Fixes the broken pages"
    task fix_broken_pages: :environment do
      Decidim::Candidacy.find_each do |candidacy|
        candidacy.components.where(manifest_name: "pages").each do |component|
          next unless Decidim::Pages::Page.where(component:).empty?

          Decidim::Pages::CreatePage.call(component) do
            on(:invalid) { raise "Cannot create page" }
          end
        end
      end
    end
  end
end
