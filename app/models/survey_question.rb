class SurveyQuestion < ApplicationRecord
  default_scope { order(:number) }

  has_many :survey_options, dependent: :destroy
  has_many :survey_responses

  accepts_nested_attributes_for :survey_options

  alias_method :options, :survey_options
  alias_method :responses, :survey_responses
end
