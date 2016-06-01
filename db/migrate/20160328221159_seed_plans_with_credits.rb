class SeedPlansWithCredits < ActiveRecord::Migration
  def up
    Plan.find_by(name: '4-class up-front discount').update(credits: 400)
    Plan.find_by(name: '5-class up-front discount').update(credits: 500)
    Plan.find_by(name: 'Loan').update(credits: 500)
    Plan.find_by(name: 'Standard tuition').update(credits: 100)
    Plan.find_by(name: 'Evening intro class').update(credits: 33)
  end

  def down
    Plan.update_all(credits: nil)
  end
end
