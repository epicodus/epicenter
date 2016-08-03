class InternshipAssignment < ActiveRecord::Base
  belongs_to :student
  belongs_to :internship
  belongs_to :course

  validates :student, presence: true
  validates :internship, presence: true
  validates :course, presence: true
  validates :student_id, uniqueness: { scope: :course_id }
end
