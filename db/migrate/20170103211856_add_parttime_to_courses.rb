class AddParttimeToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :parttime, :boolean, default: false
  end
end
