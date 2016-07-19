class InterviewAssignment < ActiveRecord::Base
  belongs_to :student
  belongs_to :internship
  belongs_to :course

  validates :student, presence: true
  validates :internship, presence: true
  validates :course, presence: true
  validates :internship_id, uniqueness: { scope: :student_id }

  scope :order_by_internship_name, -> { includes(:internship).order('internships.name') }
  scope :for_course, ->(course) { where(course_id: course.id) }

end
