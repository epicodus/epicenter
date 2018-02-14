class AddNumberOfDaysAndSkipHolidayWeeksToLanguages < ActiveRecord::Migration[5.1]
  def change
    add_column :languages, :number_of_days, :integer
    add_column :languages, :skip_holiday_weeks, :boolean
    add_column :languages, :parttime, :boolean
    add_column :languages, :online, :boolean
  end
end
