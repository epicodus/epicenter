class AddFieldsToInternships < ActiveRecord::Migration[5.2]
  def change
    add_column :internships, :mentor_name, :text
    add_column :internships, :mentor_years, :text
    add_column :internships, :work_schedule, :text
    add_column :internships, :projects, :text
    add_column :internships, :contract, :text
  end
end
