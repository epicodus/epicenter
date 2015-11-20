class Objective < ActiveRecord::Base
  validates :content, presence: true

  belongs_to :code_review
  has_many :grades

  def score_for(student)
    student_submission = code_review.submission_for(student) # calling for a particular student code review
    if student_submission && student_submission.has_been_reviewed?
      student_submission.latest_review.grades.where(objective: self).last.score.value
    else
      0
    end
  end
end
