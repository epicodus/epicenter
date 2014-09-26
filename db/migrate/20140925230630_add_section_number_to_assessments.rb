class AddSectionNumberToAssessments < ActiveRecord::Migration
  def change
    add_column :assessments, :section_number, :integer
  end
end
