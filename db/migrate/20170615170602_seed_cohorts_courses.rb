class SeedCohortsCourses < ActiveRecord::Migration
  def up
    Course.all.each do |course|
      if course.cohort_id
        cohort = Cohort.find(course.cohort_id)
        course.cohorts << cohort
        course.save
      end
    end
  end

  def down
    Course.all.each do |course|
      course.cohorts = []
    end
  end
end
