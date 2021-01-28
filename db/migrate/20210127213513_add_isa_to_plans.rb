class AddIsaToPlans < ActiveRecord::Migration[5.2]
  def change
    add_column :plans, :isa, :boolean
  end
end
