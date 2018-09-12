class SeedNewStandardPlan < ActiveRecord::Migration[5.2]
  def up
    remove_column :plans, :first_day_amount
    Plan.active.find_by(short_name: 'intro').update(archived: true, order: nil)
    Plan.active.find_by(short_name: 'fulltime-standard').update(archived: true, order: nil)
    Plan.active.find_by(short_name: 'special-grant').update(upfront: nil)
    Plan.active.find_by(short_name: 'special-gi-bill').update(upfront: nil)
    Plan.active.find_by(short_name: 'special-other').update(upfront: nil)
    Plan.create(name: 'Standard Plan ($100 then $8400)', close_io_description: '2018 - Standard Plan ($100 then $8400)', short_name: 'standard', upfront_amount: 100_00, student_portion: 8500_00, standard: true, order: 3)
  end

  def down
    add_column :plans, :first_day_amount, :integer
    Plan.find_by(short_name: 'intro').update(archived: nil)
    Plan.find_by(short_name: 'fulltime-standard').update(archived: nil)
    Plan.find_by(short_name: 'special-grant').update(upfront: true)
    Plan.find_by(short_name: 'special-gi-bill').update(upfront: true)
    Plan.find_by(short_name: 'special-other').update(upfront: true)
    Plan.find_by(close_io_description: '2018 - Standard Plan ($100 then $8400)').destroy
  end
end
