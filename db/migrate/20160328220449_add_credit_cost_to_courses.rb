class AddCreditCostToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :credit_cost, :integer
  end
end
