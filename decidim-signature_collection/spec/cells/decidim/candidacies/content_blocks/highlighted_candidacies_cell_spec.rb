# frozen_string_literal: true

require "spec_helper"

describe Decidim::Candidacies::ContentBlocks::HighlightedCandidacysCell, type: :cell do
  subject { cell(content_block.cell, content_block).call }

  let(:organization) { create(:organization) }
  let(:content_block) { create(:content_block, organization:, manifest_name: :highlighted_candidacies, scope_name: :homepage, settings:) }
  let!(:candidacies) { create_list(:candidacy, 5, organization:) }
  let!(:most_recent_candidacy) { create(:candidacy, published_at: 1.day.from_now, organization:) }
  let(:settings) { {} }

  controller Decidim::PagesController

  before do
    allow(controller).to receive(:current_organization).and_return(organization)
  end

  context "when the content block has no settings" do
    it "shows 4 candidacies" do
      expect(subject).to have_css("a.card__grid", count: 4)
    end

    it "shows up candidacies ordered by default" do
      expect(subject).not_to eq(most_recent_candidacy)
    end
  end

  context "when the content block has customized the max results setting value" do
    let(:settings) do
      {
        "max_results" => "8"
      }
    end

    it "shows up to 8 candidacies" do
      expect(subject).to have_css("a.card__grid", count: 6)
    end
  end

  context "when the content block has customized the sorting order" do
    context "when sorting by most_recent" do
      let(:settings) do
        {
          "order" => "most_recent"
        }
      end

      it "shows up candidacies ordered by published_at" do
        expect(subject.to_s.index("candidacy_#{most_recent_candidacy.id}")).to be < subject.to_s.index("candidacy_#{candidacies[4].id}")
        expect(subject.to_s.index("candidacy_#{most_recent_candidacy.id}")).to be < subject.to_s.index("candidacy_#{candidacies[3].id}")
        expect(subject.to_s.index("candidacy_#{most_recent_candidacy.id}")).to be < subject.to_s.index("candidacy_#{candidacies[2].id}")
      end
    end

    context "when sorting by default (least recent)" do
      let(:settings) do
        {
          "order" => "default"
        }
      end

      it "shows up candidacies ordered by published_at" do
        expect(subject).not_to eq(most_recent_candidacy)
      end
    end
  end
end
