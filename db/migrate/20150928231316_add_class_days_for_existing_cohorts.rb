class AddClassDaysForExistingCohorts < ActiveRecord::Migration
  def change
    Cohort.all.each do |cohort|
      cohort.update(class_days: (cohort.start_date..cohort.end_date).to_a.select { |day| day.to_s if !day.friday? && !day.saturday? && !day.sunday? }.join(','))
    end
  end
end
