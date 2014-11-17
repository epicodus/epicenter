class AddNumberToAssessments < ActiveRecord::Migration
  def change
    remove_column :assessments, :section, :string
    remove_column :assessments, :url, :string
    add_column :assessments, :number, :integer
  end
end
