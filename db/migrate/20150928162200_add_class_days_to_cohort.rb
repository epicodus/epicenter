class AddClassDaysToCohort < ActiveRecord::Migration
  def change
    add_column :cohorts, :class_days, :text
  end
end
