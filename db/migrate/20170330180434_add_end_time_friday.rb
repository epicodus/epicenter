class AddEndTimeFriday < ActiveRecord::Migration
  def change
    add_column :courses, :end_time_friday, :string
  end
end
