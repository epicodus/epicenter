class AddDeferredTuitionPaymentPlan < ActiveRecord::Migration[5.2]
  def up
    Plan.create(short_name: 'loan-deferred', name: 'Loan ($8900 deferred tuition)', close_io_description: 'Loan ($8900 deferred tuition)', loan: true, upfront_amount: 0, student_portion: 0)
    Plan.find_by(short_name: 'special-quarantine').destroy
  end

  def down
    Plan.find_by(short_name: 'loan-deferred').destroy
    Plan.create(short_name: 'special-quarantine', name: 'Special (quarantine cohort)', close_io_description: 'Quarantine cohort', upfront: true, upfront_amount: 850_00, student_portion: 850_00)
  end
end
