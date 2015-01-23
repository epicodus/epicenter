class Requirement < ActiveRecord::Base
  validates :content, presence: true

  belongs_to :assessment
  has_many :grades

  def score_for(student)
    student_submission = assessment.submission_for(student)
    if student_submission && student_submission.has_been_reviewed?
      student_submission.latest_review.grades.where(requirement: self).last.score.value
    else
      0
    end
  end
end
