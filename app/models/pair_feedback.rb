class PairFeedback < ApplicationRecord
  self.table_name = 'pair_feedback'

  Q1_OPTIONS = ["Almost never. My pair hardly worked with me at all.", "Rarely. My pair left for long stretches or worked on their own code instead of pairing with me.", "Sometimes. My pair might have left for a long stretch or two, or sometimes went off and worked on their own.", "Most of the time. My pair mostly worked with me, but disappeared for a bit or stopped working with me a time or two.", "Always. Except for occasional short breaks, my pair worked with me throughout the day."]
  Q2_OPTIONS = ["My pair was rude and unprofessional. I would not pair with them again.", "My pair was occasionally inconsiderate or unprofessional.", "Neutral. My pair was neither professional or unprofessional.", "My pair was mostly polite, considerate and professional.", "My pair was very conscientious and did a great job being polite and professional."]
  Q3_OPTIONS = ["Very poorly. We did not communicate with each other.", "Poorly. Communication was sporadic and we generally did not communicate well.", "Neutral. We communicated well enough to complete the project but there were occasional communication breakdowns or we occasionally didn’t communicate important issues.", "Well. Communication was generally smooth, though there were a few things we could’ve communicated better about.", "Excellent. We were proactive about communication throughout the day."]

  belongs_to :student
  belongs_to :pair, class_name: :Student

  validates :q1_response, presence: true
  validates :q2_response, presence: true
  validates :q3_response, presence: true

  def score
    q1_response + q2_response + q3_response
  end
end
