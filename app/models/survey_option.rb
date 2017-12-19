class SurveyOption < ApplicationRecord
  default_scope { order(:number) }

  belongs_to :survey_question
  has_many :survey_responses

  alias_method :question, :survey_question
  alias_method :responses, :survey_responses
end
