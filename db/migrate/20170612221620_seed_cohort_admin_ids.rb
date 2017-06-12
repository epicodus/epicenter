class SeedCohortAdminIds < ActiveRecord::Migration
  def up
    Cohort.where.not(track_id: nil).each do |cohort|
      cohort.admin_id = cohort.courses.first.admin_id
      cohort.save
    end
  end

  def down
    Cohort.where.not(track_id: nil).each do |cohort|
      cohort.admin_id = nil
      cohort.save
    end
  end
end
