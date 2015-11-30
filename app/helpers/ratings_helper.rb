module RatingsHelper
  def ratings_fields(internship, f, &block)
    if Rating.find_by(internship_id: internship.id, student_id: current_student.id)
      f.fields_for :ratings, Rating.find_by(internship_id: internship.id, student_id: current_student.id), &block
    else
      f.fields_for :ratings, Rating.new, &block
    end
  end
end
