class AddStartAndEndTimesToExistingCohorts < ActiveRecord::Migration
  def change
    Cohort.all.each do |cohort|
      if cohort.description == 'Intro to Programming' || cohort.description == 'Winter 2016 Intro to Programming PT'
        cohort.update(start_time: '6:05 PM', end_time: '8:30 PM')
      else
        cohort.update(start_time: '9:20 AM', end_time: '4:30 PM')
      end
    end
  end
end
