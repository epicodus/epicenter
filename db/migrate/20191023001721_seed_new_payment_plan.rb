class SeedNewPaymentPlan < ActiveRecord::Migration[5.2]
  def up
    Plan.find_by(short_name: 'parttime').update(short_name: 'parttime-intro')
    Plan.create(name: 'Part-Time Track Plan ($5400)', close_io_description: 'Part-Time Track Plan ($5400)', short_name: 'parttime-track', upfront: true, upfront_amount: 5400_00, student_portion: 5400_00)
  end

  def down
    Plan.find_by(short_name: 'parttime-track').destroy
    Plan.find_by(short_name: 'parttime-intro').update(short_name: 'parttime')
  end
end
