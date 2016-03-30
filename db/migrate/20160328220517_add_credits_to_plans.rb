class AddCreditsToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :credits, :integer
  end
end
