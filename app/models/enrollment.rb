class Enrollment < ActiveRecord::Base
  belongs_to :course
  belongs_to :student
end
