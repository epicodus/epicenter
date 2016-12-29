class AddInterviewLocationToInternships < ActiveRecord::Migration
  def change
    add_column :internships, :interview_location, :string
  end
end
