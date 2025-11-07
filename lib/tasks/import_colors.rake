# frozen_string_literal: true

namespace :import_colors do
  desc "Import colors of Participa Gencat"
  task participa: :environment do
    colors = {
      primary: "#c00000",
      secondary: "#c00000",
      tertiary: "#c0c0c0",
      success: "#57d685",
      warning: "#ffae00",
      alert: "#ec5840"
    }
    org = Decidim::Organization.first
    if org.update!(colors:)
      puts "Colors imported successfully: #{org.colors}"
    else
      puts org.errors.full_messages.to_sentence
    end
  end
end
