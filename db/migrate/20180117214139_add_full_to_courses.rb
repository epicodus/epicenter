class AddFullToCourses < ActiveRecord::Migration[5.1]
  def change
    add_column :courses, :full, :boolean
  end
end
