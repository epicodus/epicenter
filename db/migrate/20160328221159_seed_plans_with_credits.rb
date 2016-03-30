class SeedPlansWithCredits < ActiveRecord::Migration
  def up
    Plan.find_by(name: '4-class up-front discount').update(credits: 4)
    Plan.find_by(name: '5-class up-front discount').update(credits: 5)
  end

  def down
    Plan.update_all(credits: nil)
  end
end
