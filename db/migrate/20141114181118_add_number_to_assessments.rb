class AddNumberToAssessments < ActiveRecord::Migration
  def change
    add_column :assessments, :number, :integer
  end
end
