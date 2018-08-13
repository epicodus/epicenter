class SeedPlanOrder < ActiveRecord::Migration[5.2]
  def up
    Plan.active.find_by(name:"Free Intro ($100 enrollment fee)").update(order: 1)
    Plan.active.find_by(name:"Up-front Discount ($6,900 up-front)").update(order: 2)
    Plan.active.find_by(name:"Pay As You Go (4 payments of $2,125)").update(order: 3)
    Plan.active.find_by(name:"Loan ($100 enrollment fee)").update(order: 4)
    Plan.active.find_by(name:"Loan (Climb)").update(order: 5)
    Plan.active.find_by(name:"Loan (SkillsFund)").update(order: 6)
    Plan.active.find_by(name:"Loan (in process)").update(order: 7)
    Plan.active.find_by(name:"Special (3rd-party grant)").update(order: 8)
    Plan.active.find_by(name:"Special (GI Bill recipient)").update(order: 9)
    Plan.active.find_by(name:"Special (other special arrangement)").update(order: 10)
    Plan.active.find_by(name:"Evening intro class ($600)").update(order: 11, name: "Legacy - Evening intro class ($600)")
  end

  def down
    Plan.update_all(order: nil)
  end
end
