class Transcript
  TARDY_WEIGHT = 0.5

  attr_accessor :student

  def initialize(student)
    @student = student
  end

  def passing_code_reviews
    @student.cohort.code_reviews.select do |code_review|
      code_review.expectations_met_by? @student
    end
  end

  def attendance_score
    cohort_days = @student.cohort.total_class_days
    absences_penalty = @student.attendance_records_for(:absent)
    tardies_penalty = @student.attendance_records_for(:tardy) * TARDY_WEIGHT
    (cohort_days - (absences_penalty + tardies_penalty)) / cohort_days
  end

  def bottom_of_percentile_range
    ((attendance_score * 100).to_i / 5) * 5
  end
end
