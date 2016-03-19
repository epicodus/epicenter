module AttendanceHelper
  def formatted_class_days
    @course.class_dates_until(Time.zone.now.to_date).map { |day| [day.strftime("%B %d, %Y, %A"), day] }
  end

  def day_value
    @day ||= Time.zone.now.to_date
  end

  def in_class_hours
    Time.zone.now.between?(Time.zone.now.to_date + 8.hours, Time.zone.now.to_date + 16.hours + 40.minutes) ||
    Time.zone.now.between?(Time.zone.now.to_date + 18.hours, Time.zone.now.to_date + 20.hours + 40.minutes)
  end
end
