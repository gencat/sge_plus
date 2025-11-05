# frozen_string_literal: true

require "spec_helper"

describe "Admin manages candidacies" do
  STATES = Decidim::SignatureCollection::Candidacy.states.keys.map(&:to_sym)

  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, :admin, organization:) }
  let(:model_name) { Decidim::SignatureCollection::Candidacy.model_name }
  let(:resource_controller) { Decidim::SignatureCollection::Admin::CandidaciesController }
  let(:type1) { create(:candidacies_type, organization:) }
  let(:type2) { create(:candidacies_type, organization:) }
  let(:scoped_type1) { create(:candidacies_type_scope, type: type1) }
  let(:scoped_type2) { create(:candidacies_type_scope, type: type2) }
  let(:area1) { create(:area, organization:) }
  let(:area2) { create(:area, organization:) }

  def create_candidacy_with_trait(trait)
    create(:candidacy, trait, organization:)
  end

  def candidacy_with_state(state)
    Decidim::SignatureCollection::Candidacy.find_by(state:)
  end

  def candidacy_without_state(state)
    Decidim::SignatureCollection::Candidacy.where.not(state:).sample
  end

  def candidacy_with_type(type)
    Decidim::SignatureCollection::Candidacy.join(:scoped_type).find_by(decidim_candidacies_types_id: type)
  end

  def candidacy_without_type(type)
    Decidim::SignatureCollection::Candidacy.join(:scoped_type).where.not(decidim_candidacies_types_id: type).sample
  end

  def candidacy_with_area(area)
    Decidim::SignatureCollection::Candidacy.find_by(decidim_area_id: area)
  end

  def candidacy_without_area(area)
    Decidim::SignatureCollection::Candidacy.where.not(decidim_area_id: area).sample
  end

  include_context "with filterable context"

  STATES.each do |state|
    let!(:"#{state}_candidacy") { create_candidacy_with_trait(state) }
  end

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_candidacies.candidacies_path
  end

  describe "listing candidacies" do
    STATES.each do |state|
      i18n_state = I18n.t(state, scope: "decidim.admin.filters.candidacies.state_eq.values")

      context "when filtering collection by state: #{i18n_state}" do
        it_behaves_like "a filtered collection", options: "State", filter: i18n_state do
          let(:in_filter) { translated(candidacy_with_state(state).title) }
          let(:not_in_filter) { translated(candidacy_without_state(state).title) }
        end
      end
    end

    Decidim::SignatureCollection::CandidaciesTypeScope.all.each do |scoped_type|
      type = scoped_type.type
      i18n_type = type.title[I18n.locale.to_s]

      context "when filtering collection by type: #{i18n_type}" do
        before do
          create(:candidacy, organization:, scoped_type: scoped_type1)
          create(:candidacy, organization:, scoped_type: scoped_type2)
        end

        it_behaves_like "a filtered collection", options: "Type", filter: i18n_type do
          let(:in_filter) { translated(candidacy_with_type(type).title) }
          let(:not_in_filter) { translated(candidacy_without_type(type).title) }
        end
      end
    end

    it "can be searched by title" do
      search_by_text(translated(open_candidacy.title))

      expect(page).to have_content(translated(open_candidacy.title))
    end

    Decidim::Area.all.each do |area|
      i18n_area = area.name[I18n.locale.to_s]

      context "when filtering collection by area: #{i18n_area}" do
        before do
          create(:candidacy, organization:, area: area1)
          create(:candidacy, organization:, area: area2)
        end

        it_behaves_like "a filtered collection", options: "Area", filter: i18n_area do
          let(:in_filter) { translated(candidacy_with_area(area).title) }
          let(:not_in_filter) { translated(candidacy_without_area(area).title) }
        end
      end
    end

    it "can be searched by description" do
      search_by_text(translated(open_candidacy.description))

      expect(page).to have_content(translated(open_candidacy.title))
    end

    it "can be searched by id" do
      search_by_text(open_candidacy.id)

      expect(page).to have_content(translated(open_candidacy.title))
    end

    it "can be searched by author name" do
      search_by_text(open_candidacy.author.name)

      expect(page).to have_content(translated(open_candidacy.title))
    end

    it "can be searched by author nickname" do
      search_by_text(open_candidacy.author.nickname)

      expect(page).to have_content(translated(open_candidacy.title))
    end

    it_behaves_like "paginating a collection"
  end
end
