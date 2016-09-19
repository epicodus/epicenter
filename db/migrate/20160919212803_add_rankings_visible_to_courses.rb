class AddRankingsVisibleToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :rankings_visible, :boolean
  end
end
