class CourseInternship < ActiveRecord::Base
  belongs_to :course
  belongs_to :internship
end
