class Enrollment < ActiveRecord::Base
  belongs_to :course
  belongs_to :student

  validates :course, presence: true
  validates :student, presence: true
  validates :student_id, uniqueness: { scope: :course_id }
  before_save :check_student_credits, unless: ->(enrollment) { enrollment.student.plan.nil? }

private

  def check_student_credits
    if student.courses.count >= student.plan.credits
      errors.add(:student, 'has run out of credits and needs to pay for additional courses')
      false
    end
  end
end
