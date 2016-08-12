class AddTimeZoneToOffices < ActiveRecord::Migration
  def change
    add_column :offices, :time_zone, :string
  end
end
