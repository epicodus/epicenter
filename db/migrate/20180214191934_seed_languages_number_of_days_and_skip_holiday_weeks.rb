class SeedLanguagesNumberOfDaysAndSkipHolidayWeeks < ActiveRecord::Migration[5.1]
  def up
    Language.all.each do |language|
      if language.name == 'Evening'
        language.update(number_of_days: 30, skip_holiday_weeks: true, parttime: true)
      elsif language.name == 'Online'
        language.update(number_of_days: 45, skip_holiday_weeks: true, online: true)
      elsif language.name == 'Internship'
        language.update(number_of_days: 35, skip_holiday_weeks: false)
      else
        language.update(number_of_days: 24, skip_holiday_weeks: true)
      end
    end
  end

  def down
    Language.update_all(number_of_days: nil, skip_holiday_weeks: nil, parttime: nil, online: nil)
  end
end
