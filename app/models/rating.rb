class Rating < ActiveRecord::Base
  belongs_to :student
  belongs_to :internship

  validates :internship_id, presence: true, uniqueness: { scope: :student_id }

  def self.for(internship, current_student)
    if !current_student
      nil
    elsif current_student.ratings.where(internship_id: internship.id).any?
      current_student.find_rating(internship)
    else
      Rating.new
    end
  end
end
