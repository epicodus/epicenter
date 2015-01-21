class Requirement < ActiveRecord::Base
  validates :content, presence: true

  belongs_to :assessment
  has_many :grades

  def score_for(student)
    assessment.submission_for(student).latest_review.grades.where(requirement: self).last.score.value
  end
end
