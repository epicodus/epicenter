class AddClassDaysForExistingCohorts < ActiveRecord::Migration
  def up
    Cohort.all.each do |cohort|
      cohort.update(class_days: (cohort.start_date..cohort.end_date).select { |day| !day.friday? && !day.saturday? && !day.sunday? })
    end
  end

  def down
    Cohort.all.each do |cohort|
      cohort.assign_attributes(class_days: nil)
      cohort.save(validate: false)
    end
  end
end
