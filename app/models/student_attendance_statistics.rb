class StudentAttendanceStatistics
  attr_accessor :student

  def initialize(student)
    @student = student
  end

  def punctuality_hash
    {
      'On time'  => @student.on_time_attendances,
      'Tardy'    => @student.tardies,
      'Absent' => @student.absences
    }
  end

  def days_remaining
    @student.cohort.number_of_days_left
  end

  def tardies
    student.attendance_records.where(tardy: true).pluck(:date)
  end

  def absences
    class_dates_so_far = student.cohort.class_dates(Date.today)
    student_attendance_record_dates = student.attendance_records.pluck(:date)
    class_dates_so_far - student_attendance_record_dates
  end
end
