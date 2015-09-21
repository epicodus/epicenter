module AttendanceHelper
  def formatted_class_days
    @class_days.map { |day| [day.strftime("%B %d, %Y, %A"), day] }
  end

  def day_value
    @day ||= Date.today
  end
end
