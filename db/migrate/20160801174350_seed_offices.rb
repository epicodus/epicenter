class SeedOffices < ActiveRecord::Migration
  def up
    Office.create(name: 'Portland')
    Office.create(name: 'Seattle')
    Office.create(name: 'Philadelphia')
  end

  def down
    Office.destroy_all
  end
end
