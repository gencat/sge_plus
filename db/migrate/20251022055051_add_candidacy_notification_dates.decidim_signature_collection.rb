# frozen_string_literal: true

# This migration comes from decidim_signature_collection (originally 20171019103358)
class AddCandidacyNotificationDates < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_signature_collection_candidacies,
               :first_progress_notification_at, :datetime, index: { name: "idx_signaturecollect_candidacies_on_first_pgrss_notif_at" }

    add_column :decidim_signature_collection_candidacies,
               :second_progress_notification_at, :datetime, index: { name: "idx_signaturecollect_candidacies_on_second_pgrss_notif_at" }
  end
end
