class AddCohortToCourses < ActiveRecord::Migration
  def change
    add_reference :courses, :cohort, index: true, foreign_key: true
  end
end
