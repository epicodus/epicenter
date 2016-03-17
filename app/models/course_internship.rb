class CourseInternship < ActiveRecord::Base
  belongs_to :course
  belongs_to :internship

  validates :course, presence: true
  validates :internship, presence: true
  validates :internship_id, uniqueness: { scope: :course_id }
end
