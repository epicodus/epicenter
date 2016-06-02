class SeedCreditCostInCourses < ActiveRecord::Migration
  def up
    Course.update_all(credit_cost: 1)
  end

  def down
    Course.update_all(credit_cost: nil)
  end
end
