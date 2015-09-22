class CohortAttendanceStatistics
  attr_reader :cohort

  def initialize(cohort_id)
    @cohort = Cohort.find(cohort_id)
  end

  def daily_presence
    @cohort.attendance_records.unscope(:order).group(:date).count
  end

  def student_attendance_data
    students = @cohort.students.sort_by(&:absences).reverse
    [
      {
        name: "On time",
        data: students.map do |user|
          [user.name, user.on_time_attendances]
        end
      },

      {
        name: "Left early",
        data: students.map do |user|
          [user.name, user.left_earlies]
        end
      },

      {
        name: "Tardy",
        data: students.map do |user|
          [user.name, user.tardies]
        end
      },

      {
        name: "Absent",
        data: students.map do |user|
          [user.name, user.absences]
        end
      }
    ]
  end
end
