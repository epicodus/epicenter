class AddCreditCostToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :credit_cost, :decimal
  end
end
