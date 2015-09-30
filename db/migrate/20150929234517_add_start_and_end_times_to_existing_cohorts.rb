class AddStartAndEndTimesToExistingCohorts < ActiveRecord::Migration
  def change
    Cohort.where(description: ['Intro to Programming', 'Winter 2016 Intro to Programming PT']).update_all(start_time: '6:20 PM', end_time: '8:40 PM')
    Cohort.where.not(description: ['Intro to Programming', 'Winter 2016 Intro to Programming PT']).update_all(start_time: '9:20 AM', end_time: '4:30 PM')
  end
end
