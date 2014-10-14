class CreateCohorts < ActiveRecord::Migration
  def change
    create_table :cohorts do |t|
      t.string :description
      t.date :start_date
      t.date :end_date

      t.timestamps
    end

    add_column :users, :cohort_id, :integer
  end
end
