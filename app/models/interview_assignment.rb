class InterviewAssignment < ActiveRecord::Base
  belongs_to :student
  belongs_to :internship

  validates :internship_id, uniqueness: { scope: :student_id }
end
