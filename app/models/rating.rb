class Rating < ActiveRecord::Base
  belongs_to :student
  belongs_to :internship

  validates :internship_id, presence: true, uniqueness: { scope: :student_id }
end
