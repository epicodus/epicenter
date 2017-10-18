class AddShortNameToPlans < ActiveRecord::Migration[5.1]
  def change
    add_column :plans, :short_name, :string
  end
end
