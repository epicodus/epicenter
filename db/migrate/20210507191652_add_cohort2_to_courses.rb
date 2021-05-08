class AddCohort2ToCourses < ActiveRecord::Migration[5.2]
  def change
    add_reference :courses, :cohort, foreign_key: true
  end
end
