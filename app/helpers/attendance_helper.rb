module AttendanceHelper
  def formatted_class_days
    @cohort.past_and_present_class_days.map { |day| [day.strftime("%B %d, %Y, %A"), day] }
  end

  def day_value
    @day ||= Date.today
  end
end
