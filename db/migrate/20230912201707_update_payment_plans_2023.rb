class UpdatePaymentPlans2023 < ActiveRecord::Migration[7.0]
  CONFIG = {
    'standard' => {
      name: 'Standard Plan ($100 then $14,700)',
      close_io_description: '2023-2 - Standard Plan ($100 then $14,700)',
      short_name: 'standard',
      upfront_amount: 100_00,
      student_portion: 14800_00
    },
    # 'upfront' => {
    #   name: 'Up-front Discount ($9,800 up-front)',
    #   close_io_description: '2023 - Up-front Discount ($9,800 up-front)',
    #   short_name: 'upfront',
    #   upfront_amount: 9800_00,
    #   student_portion: 9800_00
    # },
    # 'isa' => {
    #   name: 'Income Share Agreement',
    #   close_io_description: 'Income Share Agreement',
    #   short_name: 'isa',
    #   upfront_amount: 0,
    #   student_portion: 0
    # },
    # 'parttime-intro' => {
    #   name: 'Evening intro class ($100)',
    #   close_io_description: 'Evening intro class ($100)',
    #   short_name: 'parttime-intro',
    #   upfront_amount: 100_00,
    #   student_portion: 100_00
    # },
    # 'loan' => {
    #   name: 'Loan ($100 enrollment fee)',
    #   close_io_description: '2018 - Loan ($100 enrollment fee)',
    #   short_name: 'fulltime-loan',
    #   upfront_amount: 100_00,
    #   student_portion: 100_00
    # },
  }

  def old_plan
    Plan.standard.find_by(student_portion: 12700_00)
  end

  def new_plan_config
    CONFIG['standard']
  end

  def new_plan # won't exist until plan is created, but useful for down method
    Plan.active.standard.find_by(student_portion: new_plan_config[:student_portion])
  end

  def up
    Plan.transaction do
      old_plan.update(archived: true)
      plan = Plan.create(
        name: new_plan_config[:name],
        close_io_description: new_plan_config[:close_io_description],
        short_name: new_plan_config[:short_name],
        upfront_amount: new_plan_config[:upfront_amount],
        student_portion: new_plan_config[:student_portion],
        standard: new_plan_config[:short_name] == 'standard',
        upfront: new_plan_config[:short_name] == 'upfront',
        isa: new_plan_config[:short_name] == 'isa',
        parttime: new_plan_config[:short_name] == 'parttime-intro',
        loan: new_plan_config[:short_name].include?('loan'),
        order: old_plan.order
      )
      update_not_fully_paid_students(old_plan: old_plan, new_plan: plan)
    end
  end

  def update_not_fully_paid_students(old_plan:, new_plan:)
    old_plan_students = Student.where(plan: old_plan)
    not_fully_paid_students = old_plan_students.select {|s| s.total_paid < old_plan.student_portion}
    students = Student.where(id: not_fully_paid_students)
    students.update_all(plan_id: new_plan.id)
  end

  def down
    Plan.transaction do
      Student.where(plan: new_plan).update_all(plan_id: old_plan.id)
      new_plan.destroy
      old_plan.update(archived: nil)
    end
  end
end
