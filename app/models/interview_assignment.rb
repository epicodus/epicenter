class InterviewAssignment < ActiveRecord::Base
  belongs_to :student
  belongs_to :internship

  validates :student, presence: true
  validates :internship, presence: true
  validates :internship_id, uniqueness: { scope: :student_id }

  scope :order_by_internship_name, -> { includes(:internship).order('internships.name') }
end
