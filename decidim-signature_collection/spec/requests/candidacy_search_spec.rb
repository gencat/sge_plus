# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Candidacy search" do
  subject { response.body }

  let(:organization) { create(:organization) }
  let(:type1) { create(:candidacies_type, organization:) }
  let(:type2) { create(:candidacies_type, organization:) }
  let(:scoped_type1) { create(:candidacies_type_scope, type: type1) }
  let(:scoped_type2) { create(:candidacies_type_scope, type: type2) }
  let(:user1) { create(:user, :confirmed, organization:, name: "John McDoggo", nickname: "john_mcdoggo") }
  let(:user2) { create(:user, :confirmed, organization:, nickname: "doggotrainer") }
  let(:group1) { create(:user_group, :confirmed, organization:, name: "The Doggo House", nickname: "the_doggo_house") }
  let(:group2) { create(:user_group, :confirmed, organization:, nickname: "thedoggokeeper") }
  let(:area1) { create(:area, organization:) }
  let(:area2) { create(:area, organization:) }

  let!(:candidacy1) { create(:candidacy, id: 999_999, title: { en: "A doggo" }, scoped_type: scoped_type1, organization:) }
  let!(:candidacy2) { create(:candidacy, description: { en: "There is a doggo in the office" }, scoped_type: scoped_type2, organization:) }
  let!(:candidacy3) { create(:candidacy, organization:) }
  let!(:area1_candidacy) { create(:candidacy, organization:, area: area1) }
  let!(:area2_candidacy) { create(:candidacy, organization:, area: area2) }
  let!(:user1_candidacy) { create(:candidacy, organization:, author: user1) }
  let!(:user2_candidacy) { create(:candidacy, organization:, author: user2) }
  let!(:group1_candidacy) { create(:candidacy, organization:, author: group1) }
  let!(:group2_candidacy) { create(:candidacy, organization:, author: group2) }
  let!(:closed_candidacy) { create(:candidacy, :acceptable, organization:) }
  let!(:accepted_candidacy) { create(:candidacy, :accepted, organization:) }
  let!(:rejected_candidacy) { create(:candidacy, :rejected, organization:) }
  let!(:answered_rejected_candidacy) { create(:candidacy, :rejected, organization:, answered_at: Time.current) }
  let!(:created_candidacy) { create(:candidacy, :created, organization:) }
  let!(:user1_created_candidacy) { create(:candidacy, :created, organization:, author: user1, signature_start_date: Date.current + 2.days, signature_end_date: Date.current + 22.days) }

  let(:filter_params) { {} }
  let(:request_path) { decidim_candidacies.candidacies_path }

  before do
    stub_const("Decidim::Paginable::OPTIONS", [100])
    get(
      request_path,
      params: { filter: filter_params },
      headers: { "HOST" => organization.host }
    )
  end

  it "displays all published open candidacies by default" do
    expect(subject).to include(decidim_escape_translated(candidacy1.title))
    expect(subject).to include(decidim_escape_translated(candidacy2.title))
    expect(subject).to include(decidim_escape_translated(candidacy3.title))
    expect(subject).to include(decidim_escape_translated(area1_candidacy.title))
    expect(subject).to include(decidim_escape_translated(area2_candidacy.title))
    expect(subject).to include(decidim_escape_translated(user1_candidacy.title))
    expect(subject).to include(decidim_escape_translated(user2_candidacy.title))
    expect(subject).to include(decidim_escape_translated(group1_candidacy.title))
    expect(subject).to include(decidim_escape_translated(group2_candidacy.title))
    expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
    expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
    expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
    expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
    expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
    expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
  end

  context "when filtering by text" do
    let(:filter_params) { { search_text_cont: search_text } }
    let(:search_text) { "doggo" }

    it "displays the candidacies containing the search in the title or the body or the author name or nickname" do
      expect(subject).to include(decidim_escape_translated(candidacy1.title))
      expect(subject).to include(decidim_escape_translated(candidacy2.title))
      expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
      expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
      expect(subject).to include(decidim_escape_translated(user1_candidacy.title))
      expect(subject).to include(decidim_escape_translated(user2_candidacy.title))
      expect(subject).to include(decidim_escape_translated(group1_candidacy.title))
      expect(subject).to include(decidim_escape_translated(group2_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
    end

    context "and the search_text is an candidacy id" do
      let(:search_text) { candidacy1.id.to_s }

      it "returns the candidacy with the searched id" do
        expect(subject).to include(decidim_escape_translated(candidacy1.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end
  end

  context "when filtering by state" do
    let(:filter_params) { { with_any_state: state } }

    context "and state is open" do
      let(:state) { %w(open) }

      it "displays only open candidacies" do
        expect(subject).to include(decidim_escape_translated(candidacy1.title))
        expect(subject).to include(decidim_escape_translated(candidacy2.title))
        expect(subject).to include(decidim_escape_translated(candidacy3.title))
        expect(subject).to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end

    context "and state is closed" do
      let(:state) { %w(closed) }

      it "displays only closed candidacies" do
        expect(subject).not_to include(decidim_escape_translated(candidacy1.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end

    context "and state is accepted" do
      let(:state) { %w(accepted) }

      it "returns only accepted candidacies" do
        expect(subject).not_to include(decidim_escape_translated(candidacy1.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end

    context "and state is rejected" do
      let(:state) { %w(rejected) }

      it "returns only rejected candidacies" do
        expect(subject).not_to include(decidim_escape_translated(candidacy1.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end

    context "and state is answered" do
      let(:state) { %w(answered) }

      it "returns only answered candidacies" do
        expect(subject).not_to include(decidim_escape_translated(candidacy1.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end

    context "and state is open or closed" do
      let(:state) { %w(open closed) }

      it "displays only closed candidacies" do
        expect(subject).to include(decidim_escape_translated(candidacy1.title))
        expect(subject).to include(decidim_escape_translated(candidacy2.title))
        expect(subject).to include(decidim_escape_translated(candidacy3.title))
        expect(subject).to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end
  end

  context "when filtering by scope" do
    let(:filter_params) { { with_any_scope: scope_id } }

    context "and a single scope id is provided" do
      let(:scope_id) { [scoped_type1.scope.id] }

      it "displays candidacies by scope" do
        expect(subject).to include(decidim_escape_translated(candidacy1.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end

    context "and multiple scope ids are provided" do
      let(:scope_id) { [scoped_type2.scope.id, scoped_type1.scope.id] }

      it "displays candidacies by scope" do
        expect(subject).to include(decidim_escape_translated(candidacy1.title))
        expect(subject).to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end
  end

  context "when filtering by author" do
    let(:filter_params) { { with_any_state: %w(open closed), author: } }

    before do
      login_as user1, scope: :user

      get(
        request_path,
        params: { filter: filter_params },
        headers: { "HOST" => organization.host }
      )
    end

    context "and author is any" do
      let(:author) { "any" }

      it "displays all candidacies except the created ones" do
        expect(subject).to include(decidim_escape_translated(candidacy1.title))
        expect(subject).to include(decidim_escape_translated(candidacy2.title))
        expect(subject).to include(decidim_escape_translated(candidacy3.title))
        expect(subject).to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end

    context "and author is myself" do
      let(:author) { "myself" }

      it "contains only candidacies of the author, including their created upcoming candidacy" do
        expect(subject).not_to include(decidim_escape_translated(candidacy1.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end
  end

  context "when filtering by type" do
    let(:filter_params) { { with_any_type: type_id } }
    let(:type_id) { [candidacy1.type.id] }

    it "displays candidacies of correct type" do
      expect(subject).to include(decidim_escape_translated(candidacy1.title))
      expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
      expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
      expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
      expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
    end

    context "and providing multiple types" do
      let(:type_id) { [candidacy1.type.id, candidacy2.type.id] }

      it "displays candidacies of correct type" do
        expect(subject).to include(decidim_escape_translated(candidacy1.title))
        expect(subject).to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).not_to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end
  end

  context "when filtering by area" do
    let(:filter_params) { { with_any_area: area_id } }

    context "when an area id is being sent" do
      let(:area_id) { [area1.id.to_s] }

      it "displays candidacies by area" do
        expect(subject).not_to include(decidim_escape_translated(candidacy1.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end

    context "and providing multiple ids" do
      let(:area_id) { [area1.id.to_s, area2.id.to_s] }

      it "displays candidacies by area" do
        expect(subject).not_to include(decidim_escape_translated(candidacy1.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy2.title))
        expect(subject).not_to include(decidim_escape_translated(candidacy3.title))
        expect(subject).to include(decidim_escape_translated(area1_candidacy.title))
        expect(subject).to include(decidim_escape_translated(area2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group1_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(group2_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(closed_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(accepted_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(answered_rejected_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(created_candidacy.title))
        expect(subject).not_to include(decidim_escape_translated(user1_created_candidacy.title))
      end
    end
  end
end
