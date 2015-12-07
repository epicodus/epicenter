module AttendanceHelper
  def formatted_class_days
    @course.class_dates_until(Time.zone.now.to_date).map { |day| [day.strftime("%B %d, %Y, %A"), day] }
  end

  def day_value
    @day ||= Time.zone.now.to_date
  end

  def attendance_notice(student)
    if student.attendance_score(current_course, current_course.number_of_days_since_start) >= 8
      'text-error'
    else
      nil
    end
  end
end
