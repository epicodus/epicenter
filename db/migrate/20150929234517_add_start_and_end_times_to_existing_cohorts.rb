class AddStartAndEndTimesToExistingCohorts < ActiveRecord::Migration
  def up
    Cohort.where(description: ['Intro to Programming', 'Winter 2016 Intro to Programming PT']).update_all(start_time: '6:00 PM', end_time: '9:00 PM')
    Cohort.where.not(description: ['Intro to Programming', 'Winter 2016 Intro to Programming PT']).update_all(start_time: '9:00 AM', end_time: '5:00 PM')
  end

  def down
    Cohort.where(description: ['Intro to Programming', 'Winter 2016 Intro to Programming PT']).update_all(start_time: nil, end_time: nil)
    Cohort.where.not(description: ['Intro to Programming', 'Winter 2016 Intro to Programming PT']).update_all(start_time: nil, end_time: nil)
  end
end
