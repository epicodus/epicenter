class Objective < ApplicationRecord
  validates :content, presence: true, length: { maximum: 255 }

  belongs_to :code_review, optional: true
  has_many :grades

  default_scope { order(:number) }

  def score_for(student)
    student_submission = code_review.submission_for(student)
    if student_submission && student_submission.has_been_reviewed? && student_submission.latest_review.grades.where(objective: self).any?
      student_submission.latest_review.grades.where(objective: self).last.score.value
    else
      0
    end
  end
end
