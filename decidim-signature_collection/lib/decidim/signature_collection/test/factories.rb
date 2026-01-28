# frozen_string_literal: true

require "decidim/faker/localized"
require "decidim/dev"

FactoryBot.define do
  factory :candidacies_type, class: "Decidim::SignatureCollection::CandidaciesType" do
    transient do
      skip_injection { false }
    end
    title { generate_localized_title(:candidacies_type_title, skip_injection:) }
    description { generate_localized_description(:candidacies_type_description, skip_injection:) }
    organization
    signature_type { :online }
    attachments_enabled { true }
    undo_online_signatures_enabled { true }
    custom_signature_end_date_enabled { false }
    area_enabled { false }
    promoting_committee_enabled { true }
    minimum_committee_members { 0 }
    child_scope_threshold_enabled { false }
    only_global_scope_enabled { false }
    comments_enabled { true }
    elections { :congress_and_senate }

    signature_period_start { Time.zone.now }
    signature_period_end { 1.month.from_now }

    trait :with_comments_disabled do
      comments_enabled { false }
    end

    trait :attachments_enabled do
      attachments_enabled { true }
    end

    trait :attachments_disabled do
      attachments_enabled { false }
    end

    trait :online_signature_enabled do
      signature_type { :online }
    end

    trait :online_signature_disabled do
      signature_type { :offline }
    end

    trait :undo_online_signatures_enabled do
      undo_online_signatures_enabled { true }
    end

    trait :undo_online_signatures_disabled do
      undo_online_signatures_enabled { false }
    end

    trait :custom_signature_end_date_enabled do
      custom_signature_end_date_enabled { true }
    end

    trait :custom_signature_end_date_disabled do
      custom_signature_end_date_enabled { false }
    end

    trait :area_enabled do
      area_enabled { true }
    end

    trait :area_disabled do
      area_enabled { false }
    end

    trait :promoting_committee_enabled do
      promoting_committee_enabled { true }
    end

    trait :promoting_committee_disabled do
      promoting_committee_enabled { false }
      minimum_committee_members { 0 }
    end

    trait :with_user_extra_fields_collection do
      collect_user_extra_fields { true }
      extra_fields_legal_information { generate_localized_description(:candidacies_type_extra_fields_legal_information, skip_injection:) }
      document_number_authorization_handler { "dummy_authorization_handler" }
    end

    trait :child_scope_threshold_enabled do
      child_scope_threshold_enabled { true }
    end

    trait :only_global_scope_enabled do
      only_global_scope_enabled { true }
    end

    trait :with_signature_period_passed do
      signature_period_start { 2.months.ago }
      signature_period_end { 1.month.ago }
    end
  end

  factory :candidacies_type_scope, class: "Decidim::SignatureCollection::CandidaciesTypeScope" do
    transient do
      skip_injection { false }
    end
    type { create(:candidacies_type, skip_injection:) }
    scope { create(:scope, organization: type.organization, skip_injection:) }
    taxonomy { create(:taxonomy, organization: type.organization, skip_injection:) }
    supports_required { 1000 }

    trait :with_user_extra_fields_collection do
      type { create(:candidacies_type, :with_user_extra_fields_collection, skip_injection:) }
    end
  end

  factory :candidacy, class: "Decidim::SignatureCollection::Candidacy" do
    transient do
      skip_injection { false }
    end

    title { generate_localized_title(:candidacy_title, skip_injection:) }
    description { generate_localized_description(:candidacy_description, skip_injection:) }
    organization
    author { create(:user, :confirmed, organization:, skip_injection:) }
    state { "open" }
    published_at { Time.current.utc }
    signature_type { "online" }
    signature_start_date { Date.current - 1.day }
    signature_end_date { Date.current + 120.days }

    scoped_type do
      create(:candidacies_type_scope, skip_injection:,
                                      type: create(:candidacies_type, organization:, signature_type:, skip_injection:))
    end

    after(:create) do |candidacy, evaluator|
      if candidacy.author.is_a?(Decidim::User) && Decidim::Authorization.where(user: candidacy.author).where.not(granted_at: nil).none?
        create(:authorization, user: candidacy.author, granted_at: Time.now.utc, skip_injection: evaluator.skip_injection)
      end
      create_list(:candidacies_committee_member, 3, candidacy:, skip_injection: evaluator.skip_injection)
    end

    trait :created do
      state { "created" }
      published_at { nil }
    end

    trait :validating do
      state { "validating" }
      published_at { nil }
    end

    trait :open do
      state { "open" }
    end

    trait :accepted do
      state { "accepted" }
    end

    trait :discarded do
      state { "discarded" }
    end

    trait :rejected do
      state { "rejected" }
    end

    trait :online do
      signature_type { "online" }
    end

    trait :offline do
      signature_type { "offline" }
    end

    trait :acceptable do
      signature_type { "online" }

      after(:build) do |candidacy|
        candidacy.type.signature_period_start = Date.current - 4.months
        candidacy.type.signature_period_end = Date.current - 1.month
        candidacy.type.save!
        candidacy.online_votes[candidacy.scope.id.to_s] = candidacy.supports_required + 1
        candidacy.online_votes["total"] = candidacy.supports_required + 1
      end
    end

    trait :rejectable do
      signature_type { "online" }

      after(:build) do |candidacy|
        candidacy.type.signature_period_start = Date.current - 4.months
        candidacy.type.signature_period_end = Date.current - 1.month
        candidacy.type.save!
        candidacy.online_votes[candidacy.scope.id.to_s] = 0
        candidacy.online_votes["total"] = 0
      end
    end

    trait :with_user_extra_fields_collection do
      scoped_type do
        create(:candidacies_type_scope, skip_injection:,
                                        type: create(:candidacies_type, :with_user_extra_fields_collection, organization:, skip_injection:))
      end
    end

    trait :with_area do
      area { create(:area, organization:, skip_injection:) }
    end

    trait :with_documents do
      transient do
        documents_number { 2 }
      end

      after :create do |candidacy, evaluator|
        evaluator.documents_number.times do
          candidacy.attachments << create(
            :attachment,
            :with_pdf,
            attached_to: candidacy,
            skip_injection: evaluator.skip_injection
          )
        end
      end
    end
  end

  factory :candidacy_user_vote, class: "Decidim::SignatureCollection::CandidaciesVote" do
    transient do
      skip_injection { false }
    end
    candidacy { create(:candidacy, skip_injection:) }
    hash_id { SecureRandom.uuid }
    after(:create) do |vote|
      vote.candidacy.update_online_votes_counters
    end
  end

  factory :organization_user_vote, class: "Decidim::SignatureCollection::CandidaciesVote" do
    transient do
      skip_injection { false }
    end
    candidacy { create(:candidacy, skip_injection:) }
    author { create(:user, :confirmed, organization: candidacy.organization, skip_injection:) }
    decidim_user_group_id { create(:user_group, skip_injection:).id }
    after(:create) do |support, evaluator|
      create(:user_group_membership, user: support.author, user_group: Decidim::UserGroup.find(support.decidim_user_group_id), skip_injection: evaluator.skip_injection)
    end
  end

  factory :candidacies_committee_member, class: "Decidim::SignatureCollection::CandidaciesCommitteeMember" do
    transient do
      skip_injection { false }
    end
    candidacy { create(:candidacy, skip_injection:) }
    user { create(:user, :confirmed, organization: candidacy.organization, skip_injection:) }
    state { "accepted" }

    trait :accepted do
      state { "accepted" }
    end

    trait :requested do
      state { "requested" }
    end

    trait :rejected do
      state { "rejected" }
    end
  end

  factory :candidacies_settings, class: "Decidim::SignatureCollection::CandidaciesSettings" do
    transient do
      skip_injection { false }
    end
    candidacies_order { "random" }
    organization

    trait :most_recent do
      candidacies_order { "date" }
    end

    trait :most_signed do
      candidacies_order { "signatures" }
    end

    trait :most_commented do
      candidacies_order { "comments" }
    end

    trait :most_recently_published do
      candidacies_order { "publication_date" }
    end
  end
end
