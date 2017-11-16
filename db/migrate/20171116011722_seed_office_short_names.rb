class SeedOfficeShortNames < ActiveRecord::Migration[5.1]
  def up
    Office.find_by(name: 'Portland').update(short_name: 'PDX')
    Office.find_by(name: 'Seattle').update(short_name: 'SEA')
    Office.find_by(name: 'Philadelphia').update(short_name: 'PHL')
  end

  def down
    Office.update_all(short_name: nil)
  end
end
