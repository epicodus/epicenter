class AddOfficeIdToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :office_id, :integer
  end
end
