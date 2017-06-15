class CreateCohortsCourses < ActiveRecord::Migration
  def change
    create_table :cohorts_courses do |t|
      t.belongs_to :cohort
      t.belongs_to :course
    end
  end
end
