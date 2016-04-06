module AttendanceHelper
  def formatted_class_days
    @course.class_dates_until(Time.zone.now.to_date).map { |day| [day.strftime("%B %d, %Y, %A"), day] }
  end

  def day_value
    @day ||= Time.zone.now.to_date
  end

  def in_class_hours(beginning_hour, end_hour, end_minute)
    Time.zone.now.between?(Time.zone.now.to_date + beginning_hour.hours, Time.zone.now.to_date + end_hour.hours + end_minute.minutes)
  end
end
