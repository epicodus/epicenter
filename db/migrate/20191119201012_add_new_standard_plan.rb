class AddNewStandardPlan < ActiveRecord::Migration[5.2]
  def up
    Plan.find_by(name: 'Standard Plan ($100 then $8400)').update(archived: true)
    Plan.create(name: 'Standard Plan ($100 then $8800)', close_io_description: '2020 - Standard Plan ($100 then $8800)', upfront_amount: 10000, student_portion: 890000, standard: true, short_name: 'standard', order: 3)
  end

  def down
    Plan.find_by(name: 'Standard Plan ($100 then $8800)').destroy
    Plan.find_by(name: 'Standard Plan ($100 then $8400)').update(archived: nil)
  end
end
