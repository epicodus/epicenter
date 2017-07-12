class Objective < ApplicationRecord
  validates :content, presence: true

  belongs_to :code_review
  has_many :grades

  def score_for(student)
    student_submission = code_review.submission_for(student)
    if student_submission && student_submission.has_been_reviewed? && student_submission.latest_review.grades.where(objective: self).any?
      student_submission.latest_review.grades.where(objective: self).last.score.value
    else
      0
    end
  end
end
