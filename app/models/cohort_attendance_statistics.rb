class CohortAttendanceStatistics
  attr_reader :cohort

  def initialize(cohort_id)
    @cohort = Cohort.find(cohort_id)
  end

  def daily_presence
    @cohort.attendance_records.where("date between ? and ?", @cohort.start_date, @cohort.end_date).unscope(:order).group(:date).count
  end

  def student_attendance_data
    students = @cohort.students.sort_by { |student| student.attendance_records_for(:absent) }.reverse
    [
      {
        name: "On time",
        data: students.map do |user|
          [user.name, user.attendance_records_for(:on_time)]
        end
      },

      {
        name: "Left early",
        data: students.map do |user|
          [user.name, user.attendance_records_for(:left_early)]
        end
      },

      {
        name: "Tardy",
        data: students.map do |user|
          [user.name, user.attendance_records_for(:tardy)]
        end
      },

      {
        name: "Absent",
        data: students.map do |user|
          [user.name, user.attendance_records_for(:absent)]
        end
      }
    ]
  end
end
