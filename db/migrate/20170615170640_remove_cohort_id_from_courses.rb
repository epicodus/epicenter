class RemoveCohortIdFromCourses < ActiveRecord::Migration
  def change
    remove_column :courses, :cohort_id, :integer
  end
end
