class CourseAttendanceStatistics
  attr_reader :course

  def initialize(course_id)
    @course = Course.find(course_id)
  end

  def daily_presence
    @course.attendance_records.where("date between ? and ?", @course.start_date, @course.end_date).unscope(:order).group(:date).count
  end

  def student_attendance_data
    students = @course.students.sort_by { |student| student.attendance_records_for(:absent, @course) }.reverse
    [
      {
        name: "On time",
        data: students.map do |user|
          [user.name, user.attendance_records_for(:on_time, @course)]
        end
      },

      {
        name: "Left early",
        data: students.map do |user|
          [user.name, user.attendance_records_for(:left_early, @course)]
        end
      },

      {
        name: "Tardy",
        data: students.map do |user|
          [user.name, user.attendance_records_for(:tardy, @course)]
        end
      },

      {
        name: "Absent",
        data: students.map do |user|
          [user.name, user.attendance_records_for(:absent, @course)]
        end
      }
    ]
  end
end
