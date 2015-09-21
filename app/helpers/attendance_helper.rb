module AttendanceHelper
  def formatted_class_days
    @class_days.map { |day| [day.strftime("%B %d, %Y, %A"), day] }
  end

  def day_value
    @day ||= Date.today
  end

  def past_and_present_class_days
    @cohort.list_class_days.select { |day| day if day <= Date.today  }
  end
end
