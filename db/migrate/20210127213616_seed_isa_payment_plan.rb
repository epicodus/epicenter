class SeedIsaPaymentPlan < ActiveRecord::Migration[5.2]
  def up
    Plan.create(name: 'Income Share Agreement', close_io_description: 'Income Share Agreement', short_name: 'isa', isa: true, upfront_amount: 0, student_portion: 0, order: 1)
  end

  def down
    Plan.find_by(short_name: 'isa').destroy
  end
end
