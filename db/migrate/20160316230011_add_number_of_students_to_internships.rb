class AddNumberOfStudentsToInternships < ActiveRecord::Migration
  def change
    add_column :internships, :number_of_students, :integer
  end
end
