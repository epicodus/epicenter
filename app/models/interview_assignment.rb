class InterviewAssignment < ApplicationRecord
  belongs_to :student
  belongs_to :internship
  belongs_to :course

  validates :student, presence: true
  validates :internship, presence: true
  validates :course, presence: true
  validates :internship_id, uniqueness: { scope: [:student_id, :course_id] }

  scope :order_by_internship_name, -> { includes(internship: :company).order('internships.name') }
  scope :for_course, ->(course) { where(course_id: course.id) }
  scope :for_internship, ->(internship) { where(internship_id: internship.id).includes(:student).order(:ranking_from_company) }
  scope :with_feedback_from_company, -> { where.not(feedback_from_company: nil) }
end
