module WeekdayHelper
  def is_weekday?
    !Date.today.saturday? && !Date.today.sunday?
  end
end
