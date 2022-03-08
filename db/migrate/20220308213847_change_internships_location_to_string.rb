class ChangeInternshipsLocationToString < ActiveRecord::Migration[5.2]
  def up
    change_column :internships, :location, :string
    Internship.where(location: '0').update_all(location: 'onsite')
    Internship.where(location: '1').update_all(location: 'remote')
    Internship.where(location: '2').update_all(location: 'either')
  end

  def down
    Internship.where(location: 'onsite').update_all(location: '0')
    Internship.where(location: 'remote').update_all(location: '1')
    Internship.where(location: 'either').update_all(location: '2')
    change_column :internships, :location, 'integer USING CAST(location AS integer)'
  end
end
