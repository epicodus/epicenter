class SurveyResponse < ApplicationRecord
  belongs_to :student
  belongs_to :survey_question
  belongs_to :survey_option

  validates :survey_question_id, uniqueness: { scope: :student_id }
  validates :student_id, uniqueness: { scope: :survey_question_id }

  alias_method :question, :survey_question
  alias_method :selected_option, :survey_option

  # def self.calculate_results(code_review)
  #   surveys = code_review.surveys
  #
  #
  #
  #
  #   results = {}
  #   fields = Survey.column_names.reject { |field| field.end_with?('id') || field.end_with?('_at') }
  #   fields.each do |field|
  #     if field.end_with?('_note')
  #       results[field] = '' unless results[field]
  #       results[field] += field
  #     else
  #       results[field] = 0 unless results[field]
  #       results[field] += field
  #     end
  #   end
  # end
end
