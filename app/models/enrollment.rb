class Enrollment < ActiveRecord::Base
  belongs_to :course
  belongs_to :student

  validates :course, presence: true
  validates :student, presence: true
end
