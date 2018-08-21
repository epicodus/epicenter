class AddStudentPortionToPlans < ActiveRecord::Migration[5.2]
  def up
    add_column :plans, :student_portion, :integer
    Plan.all.each do |plan|
      if plan.standard?
        plan.update(student_portion: plan.first_day_amount * 4 + 10000)
      else
        plan.update(student_portion: plan.upfront_amount)
      end
    end
  end

  def down
    remove_column :plans, :student_portion
  end
end
