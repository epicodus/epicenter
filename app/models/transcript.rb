class Transcript
  TARDY_WEIGHT = 0.5

  attr_accessor :student

  def initialize(student)
    @student = student
  end

  def passing_code_reviews
    @student.course.code_reviews.select do |code_review|
      code_review.expectations_met_by? @student
    end
  end

  def attendance_score
    course_days = @student.course.total_class_days
    absences_penalty = @student.attendance_records_for(:absent)
    tardies_penalty = @student.attendance_records_for(:tardy) * TARDY_WEIGHT
    (course_days - (absences_penalty + tardies_penalty)) / course_days
  end

  def bottom_of_percentile_range
    ((attendance_score * 100).to_i / 5) * 5
  end
end
