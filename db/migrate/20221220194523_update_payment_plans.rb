class UpdatePaymentPlans < ActiveRecord::Migration[6.1]
  def up
    Plan.active.upfront.last.update(archived: true)
    Plan.active.standard.last.update(archived: true)
    Plan.create(name: "Up-front Discount ($9,800 up-front)", close_io_description: "2023 - Up-front Discount ($9,800 up-front)", short_name: 'upfront', upfront_amount: 9800_00, student_portion: 9800_00, upfront: true, order: 2)
    Plan.create(name: 'Standard Plan ($100 then $12,600)', close_io_description: '2023 - Standard Plan ($100 then $12,600)', short_name: 'standard', upfront_amount: 100_00, student_portion: 12700_00, standard: true, order: 3)
  end

  def down
    Plan.active.upfront.last.update(archived: true)
    Plan.active.standard.last.update(archived: true)
    Plan.find_by(student_portion: 8700_00).update(archived: nil)
    Plan.find_by(student_portion: 11700_00).update(archived: nil)
  end
end
