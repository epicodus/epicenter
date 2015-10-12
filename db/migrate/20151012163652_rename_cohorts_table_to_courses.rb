class RenameCohortsTableToCourses < ActiveRecord::Migration
  def change
    rename_table :cohorts, :courses
  end
end
