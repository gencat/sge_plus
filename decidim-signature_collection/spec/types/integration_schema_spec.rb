# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/signature_collection/test/factories"

describe "Decidim::Api::QueryType" do
  include_context "with a graphql class type"
  let(:schema) { Decidim::Api::Schema }

  let(:locale) { "en" }
  let!(:candidacy) { create(:candidacy, organization: current_organization) }

  let(:candidacy_data) do
    {
      "attachments" => [],
      "author" => { "id" => candidacy.author.id.to_s },
      "committeeMembers" => candidacy.committee_members.map do |cm|
        {
          "createdAt" => cm.created_at.to_time.iso8601,
          "id" => cm.id.to_s,
          "state" => cm.state,
          "updatedAt" => cm.updated_at.to_time.iso8601,
          "user" => { "id" => cm.decidim_users_id.to_s }
        }
      end,
      "components" => [],
      "createdAt" => candidacy.created_at.to_time.iso8601,
      "description" => { "translation" => candidacy.description[locale] },
      "id" => candidacy.id.to_s,
      "offlineVotes" => candidacy.offline_votes_count,
      "onlineVotes" => candidacy.online_votes_count,
      "publishedAt" => candidacy.published_at.to_time.iso8601,
      "reference" => candidacy.reference,
      "scope" => { "id" => candidacy.scope.id.to_s },
      "signatureEndDate" => candidacy.signature_end_date.to_date.to_s,
      "signatureStartDate" => candidacy.signature_start_date.to_date.to_s,
      "signatureType" => candidacy.signature_type,
      "slug" => candidacy.slug,
      "state" => candidacy.state,
      "title" => { "translation" => candidacy.title[locale] },
      "type" => candidacy.class.name,
      "updatedAt" => candidacy.updated_at.to_time.iso8601

    }
  end
  let(:candidacy_type_data) do
    {
      "collectUserExtraFields" => true,
      "createdAt" => candidacy.type.created_at.to_time.iso8601,
      "description" => { "translation" => candidacy.type.description[locale] },
      "extraFieldsLegalInformation" => candidacy.type.extra_fields_legal_information,
      "id" => candidacy.type.id.to_s,
      "candidacies" => candidacy.type.candidacies.map { |i| { "id" => i.id.to_s } },
      "minimumCommitteeMembers" => candidacy.type.minimum_committee_members,
      "promotingCommitteeEnabled" => candidacy.type.promoting_committee_enabled,
      "signatureType" => candidacy.type.signature_type,
      "title" => { "translation" => candidacy.type.title[locale] },
      "undoOnlineSignaturesEnabled" => candidacy.type.undo_online_signatures_enabled,
      "updatedAt" => candidacy.type.updated_at.to_time.iso8601
    }
  end

  let(:candidacies) do
    %(
      candidacies{
        attachments {
          thumbnail
        }
        author {
          id
        }
        committeeMembers {
          createdAt
          id
          state
          updatedAt
          user { id }
        }
        components {
          id
        }
        createdAt
        description {
          translation(locale: "#{locale}")
        }
        id
        candidacyType {
          bannerImage
          collectUserExtraFields
          createdAt
          description {
          translation(locale: "#{locale}")
          }
          extraFieldsLegalInformation
          id
          candidacies{id}
          minimumCommitteeMembers
          promotingCommitteeEnabled
          signatureType
          title {
                  translation(locale: "#{locale}")

          }
          undoOnlineSignaturesEnabled
          updatedAt
        }
        offlineVotes
        onlineVotes
        publishedAt
        reference
        scope {
          id
        }
        signatureEndDate
        signatureStartDate
        signatureType
        slug
        state
        title {
          translation(locale: "#{locale}")
        }
        type
        updatedAt
      }
    )
  end

  let(:query) do
    %(
      query {
        #{candidacies}
      }
    )
  end

  describe "valid query" do
    it "executes successfully" do
      expect { response }.not_to raise_error
    end

    it "returns the correct response" do
      data = response["candidacies"].first
      expect(data).to include(candidacy_data)
      expect(data["candidacyType"]).to include(candidacy_type_data)
      expect(data["candidacyType"]["bannerImage"]).to be_blob_url(candidacy.type.banner_image.blob)
    end

    it_behaves_like "implements stats type" do
      let(:candidacies) do
        %(
          candidacies {
            stats{
              name
              value
            }
          }
        )
      end
      let(:stats_response) { response["candidacies"].first["stats"] }
    end
  end

  describe "single candidacy" do
    let(:candidacies) do
      %(
      candidacy(id: #{candidacy.id}){
        attachments {
          thumbnail
        }
        author {
          id
        }
        committeeMembers {
          createdAt
          id
          state
          updatedAt
          user { id }
        }
        components {
          id
        }
        createdAt
        description {
          translation(locale: "en")
        }
        id
        candidacyType {
          bannerImage
          collectUserExtraFields
          createdAt
          description {
          translation(locale: "en")
          }
          extraFieldsLegalInformation
          id
          candidacies{id}
          minimumCommitteeMembers
          promotingCommitteeEnabled
          signatureType
          title {
                  translation(locale: "en")

          }
          undoOnlineSignaturesEnabled
          updatedAt
        }
        offlineVotes
        onlineVotes
        publishedAt
        reference
        scope {
          id
        }
        signatureEndDate
        signatureStartDate
        signatureType
        slug
        state
        title {
          translation(locale: "en")
        }
        type
        updatedAt
      }
    )
    end

    it "executes successfully" do
      expect { response }.not_to raise_error
    end

    it "returns the correct response" do
      data = response["candidacy"]
      expect(data).to include(candidacy_data)
      expect(data["candidacyType"]).to include(candidacy_type_data)
      expect(data["candidacyType"]["bannerImage"]).to be_blob_url(candidacy.type.banner_image.blob)
    end

    it_behaves_like "implements stats type" do
      let(:candidacies) do
        %(
          candidacy(id: #{candidacy.id}){
            stats{
              name
              value
            }
          }
        )
      end
      let(:stats_response) { response["candidacy"]["stats"] }
    end
  end
end
