class PairFeedback < ApplicationRecord
  self.table_name = 'pair_feedback'
  scope :today, -> { where(created_at: Time.zone.now.to_date.all_day) }

  Q1_OPTIONS = ["Always. Except for occasional short breaks, my pair worked with me throughout the day.", "Most of the time. My pair mostly worked with me, but disappeared for a bit or stopped working with me a time or two.", "Sometimes. My pair might have left for a long stretch or two, or sometimes went off and worked on their own.", "Rarely. My pair left for long stretches or worked on their own code instead of pairing with me.", "Almost never. My pair hardly worked with me at all."]
  Q2_OPTIONS = ["My pair was very conscientious and did a great job being polite and professional.", "My pair was mostly polite, considerate and professional.", "Neutral. My pair was neither professional nor unprofessional.", "My pair was occasionally inconsiderate, unprofessional, or made me uncomfortable.", "My pair was rude, unprofessional, and/or made me uncomfortable. I would not pair with them again."]
  Q3_OPTIONS = ["Always or almost always. My pair made sure we spent even time driving, and when they were driving, they always listened to me and considered my ideas.", "Most of the time. My pair drove a bit more than me and usually considered my ideas when they were driving.", "Sometimes. Multiple times my pair took more than their fair share of driving and/or was sometimes dismissive or ignored my ideas.", "Rarely. I only got to drive a few times and/or my pair disregarded my input when they were driving.", "Never or almost never. It was difficult for me to get any time driving, and when my pair was driving, they totally disregarded my input."]

  belongs_to :student
  belongs_to :pair, class_name: :Student

  validates :q1_response, presence: true
  validates :q2_response, presence: true
  validates :q3_response, presence: true

  def score
    q1_response + q2_response + q3_response
  end

  def self.average(student, course)
    evals = student.evaluations_by_pairs.where(created_at: course.start_date.beginning_of_day..course.end_date.end_of_day)
    if evals.any?
      evals.map {|eval| eval.score}.sum / evals.count
    else
      '-'
    end
  end
end
