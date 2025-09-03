# frozen_string_literal: true

# This migration comes from decidim_forms (originally 20241122142230)
# This file has been modified by `decidim upgrade:migrations` task on 2025-09-03 08:54:23 UTC
class AddSurveyAnswersPublishedAtToQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_forms_questions, :survey_answers_published_at, :datetime, index: true
  end
end
