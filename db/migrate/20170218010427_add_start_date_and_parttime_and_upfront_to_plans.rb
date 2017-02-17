class AddStartDateAndParttimeAndUpfrontToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :start_date, :date
    add_column :plans, :parttime, :boolean
    add_column :plans, :upfront, :boolean
  end
end
