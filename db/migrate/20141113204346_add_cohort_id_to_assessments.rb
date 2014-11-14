class AddCohortIdToAssessments < ActiveRecord::Migration
  def change
    add_column :assessments, :cohort_id, :integer
  end
end
