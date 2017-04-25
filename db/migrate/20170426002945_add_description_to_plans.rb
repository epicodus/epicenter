class AddDescriptionToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :description, :string
  end
end
