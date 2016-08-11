class SeedOfficesWithTimeZones < ActiveRecord::Migration
  def up
    Office.update_all(time_zone: 'Pacific Time (US & Canada)')
    Office.find_by(name: 'Philadelphia').update(time_zone: 'Eastern Time (US & Canada)')
  end

  def down
    Office.update_all(time_zone: nil)
  end
end
