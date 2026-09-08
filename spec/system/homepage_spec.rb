# frozen_string_literal: true

require "rails_helper"

describe "Homepage" do
  let!(:organization) do
    create(
      :organization,
      name: { ca: "SGE Plus" },
      default_locale: :en,
      available_locales: [:ca, :en, :es]
    )
  end
  let!(:hero) do
    create(:content_block, organization: organization, scope_name: :homepage, manifest_name: :hero, settings: {
             "welcome_text_ca" => "Benvinguda a SGE+"
           })
  end
  let!(:sub_hero) do
    create(:content_block, organization: organization, scope_name: :homepage, manifest_name: :sub_hero)
  end

  before do
    switch_to_host(organization.host)
    visit decidim.root_path(locale: I18n.locale)
  end

  it "loads and shows organization name and main blocks" do
    visit decidim.root_path

    expect(page).to have_content("SGE+")
    within "section.hero__container .hero__title" do
      expect(page).to have_content("Benvinguda a SGE+")
    end
  end
  
  context "when having homepage anchors" do
    %w(hero sub_hero).each do |anchor|
      it { expect(page).to have_css("[id^=#{anchor}]", visible: :all) }
    end
  end
end
