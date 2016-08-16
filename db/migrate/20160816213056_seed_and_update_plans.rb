class SeedAndUpdatePlans < ActiveRecord::Migration
  def up
    Plan.create(name: '2017 Standard tuition', upfront_amount: 10000, standard: true, first_day_amount: 140000)
    Plan.create(name: '2017 5-class up-front discount', upfront_amount: 480000)
    Plan.find_by(name: '5-class up-front discount').update(name: '2016 5-class up-front discount')
    Plan.find_by(name: 'Standard tuition').update(name: '2016 Standard tuition', first_day_amount: 110000)
  end

  def down
    Plan.find_by(name: '2017 Standard tuition').destroy
    Plan.find_by(name: '2017 5-class up-front discount').destroy
    Plan.find_by(name: '2016 5-class up-front discount').update(name: '5-class up-front discount')
    Plan.find_by(name: '2016 Standard tuition').update(name: 'Standard tuition', first_day_amount: nil)
  end
end
