class MigrateCostAdjustmentsToCustomUpfrontTuition < ActiveRecord::Migration[5.2]
  def up
    students = Student.where(id: CostAdjustment.pluck(:student_id))
    students.each do |student|
      student.upfront_amount = student.plan.upfront_amount + student.cost_adjustments.sum(:amount)
      student.save
    end
  end

  def down
    students = Student.where.not(upfront_amount: nil)
    students.each do |student|
      student.cost_adjustments.create(amount: student.upfront_amount - student.plan.upfront_amount, reason: 'recreated from custom upfront tuition')
    end
  end
end
