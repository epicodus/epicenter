class AddClassDaysForExistingCohorts < ActiveRecord::Migration
  def change
    Cohort.all.each do |cohort|
      cohort.update(class_days: (cohort.start_date..cohort.end_date).select { |day| !day.friday? && !day.saturday? && !day.sunday? })
    end
  end
end
