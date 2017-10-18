class SeedPlanShortNames < ActiveRecord::Migration[5.1]
  def up
    Plan.where(upfront: true).update_all(short_name: 'upfront')
    Plan.where(standard: true).update_all(short_name: 'standard')
    Plan.where(loan: true).update_all(short_name: 'loan')
    Plan.where(parttime: true).update_all(short_name: 'parttime')
  end

  def down
    Plan.update_all(short_name: nil)
  end
end
