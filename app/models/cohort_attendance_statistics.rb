class CohortAttendanceStatistics
  attr_reader :cohort

  def initialize(cohort_id)
    @cohort = Cohort.find(cohort_id)
  end

  def daily_presence
    @cohort.attendance_records.where("date between ? and ?", @cohort.start_date, @cohort.end_date).unscope(:order).group(:date).count
  end

  def student_attendance_data
    students = @cohort.students.sort_by(&:absences).reverse
    [
      {
        name: "On time",
        data: students.map do |user|
          [user.name, user.attendance_records_for_current_cohort(tardy: false, left_early: false)]
        end
      },

      {
        name: "Left early",
        data: students.map do |user|
          [user.name, user.attendance_records_for_current_cohort(left_early: true)]
        end
      },

      {
        name: "Tardy",
        data: students.map do |user|
          [user.name, user.attendance_records_for_current_cohort(tardy: true)]
        end
      },

      {
        name: "Absent",
        data: students.map do |user|
          [user.name, user.absences_for_cohort]
        end
      }
    ]
  end
end
