class Survey < ApplicationRecord
  has_many :code_reviews
  has_many :survey_questions, dependent: :destroy
  has_many :survey_responses, through: :survey_questions

  accepts_nested_attributes_for :survey_questions

  alias_method :questions, :survey_questions
  alias_method :responses, :survey_responses
end
