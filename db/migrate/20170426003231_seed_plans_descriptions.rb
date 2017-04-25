class SeedPlansDescriptions < ActiveRecord::Migration
  def up
    Plan.rates_2016.update_all(description: "2016 rates")
    Plan.rates_2017.update_all(description: "2017 rates")
  end

  def down
    Plan.update_all(description: nil)
  end
end
