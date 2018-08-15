class RemoveStartDateAndDescriptionFromPlans < ActiveRecord::Migration[5.2]
  def up
    remove_column :plans, :start_date
    remove_column :plans, :description
  end

  def down
    add_column :plans, :start_date, :date
    add_column :plans, :description, :string
  end
end
