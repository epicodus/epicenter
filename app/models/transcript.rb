class Transcript
  TARDY_WEIGHT = 0.5

  attr_reader :student

  def initialize(student)
    @student = student
  end

  def passing_assessments
    @student.cohort.assessments.select do |assessment|
      assessment.expectations_met_by? @student
    end
  end

  def attendance_score
    cohort_days = @student.cohort.total_class_days
    absences_penalty = @student.absences
    tardies_penalty = @student.tardies * TARDY_WEIGHT
    (cohort_days - (absences_penalty + tardies_penalty)) / cohort_days
  end

  def bottom_of_percentile_range
    ((attendance_score * 100).to_i / 5) * 5
  end
end
