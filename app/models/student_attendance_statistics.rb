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
end
