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
          [user.name, user.on_time_attendances_for_cohort]
        end
      },

      {
        name: "Left early",
        data: students.map do |user|
          [user.name, user.left_earlies_for_cohort]
        end
      },

      {
        name: "Tardy",
        data: students.map do |user|
          [user.name, user.tardies_for_cohort]
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
