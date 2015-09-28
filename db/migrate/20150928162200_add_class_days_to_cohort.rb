class AddClassDaysToCohort < ActiveRecord::Migration
  def change
    add_column :cohorts, :class_days, :string
  end
end
