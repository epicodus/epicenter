class CohortAttendanceStatistics
  attr_reader :cohort

  def initialize(cohort)
    @cohort = cohort
  end

  def daily_presence
    @cohort.attendance_records.group('DATE(attendance_records.created_at)').count
  end

  def student_breakdown # this is a terrible name
    students = @cohort.students.sort_by(&:absences).reverse
    [
      {
        name: "On time",
        data: students.map do |user|
          [user.name, user.on_time_attendances]
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
