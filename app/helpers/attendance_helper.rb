module AttendanceHelper
  def formatted_class_days
    @course.class_dates_until(Time.zone.now.to_date).map { |day| [day.strftime("%B %d, %Y, %A"), day] }
  end

  def day_value
    @day ||= Time.zone.now.to_date
  end
end
