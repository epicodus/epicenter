class AddSpecialQuarantinePaymentPlan < ActiveRecord::Migration[5.2]
  def up
    Plan.create(short_name: 'special-quarantine', name: 'Special (quarantine cohort)', close_io_description: 'Quarantine cohort', upfront: true, upfront_amount: 850_00, student_portion: 850_00)
  end

  def down
    Plan.find_by(short_name: 'special-quarantine').destroy
  end
end
