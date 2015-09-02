  class Rating < ActiveRecord::Base
  belongs_to :student
  belongs_to :internship

  validates :internship_id, presence: true, uniqueness: { scope: :student_id }
  validate :no_more_than_five_lowest

  def self.for(internship, current_student)
    if !current_student
      nil
    elsif current_student.ratings.where(internship_id: internship.id).any?
      current_student.find_rating(internship)
    else
      current_student.ratings.new
    end
  end

private

  def no_more_than_five_lowest
    if interest == "3" && student.ratings.where(interest: 3).count == 5
      errors.add(:interest, "cannot be low for more than 5 companies.")
      false
    end
  end
end
