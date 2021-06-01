class RemoveStudentEndingCohortAndOffice < ActiveRecord::Migration[5.2]
  def change
    remove_reference :users, :office, index: true, foreign_key: true
    remove_column :users, :ending_cohort_id, :integer
  end
end
