class ChangeInternshipsLocationToEnum < ActiveRecord::Migration[5.2]
  def up
    change_column :internships, :location, :integer, :using => 'case when location then 1 else 0 end'
  end

  def down
    change_column :internships, :location, :boolean, :using => 'case when location = 1 then true else false end'
  end
end
