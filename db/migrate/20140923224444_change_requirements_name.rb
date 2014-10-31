class ChangeRequirementsName < ActiveRecord::Migration
  def change
    rename_table :assessment_requirements, :requirements
  end
end
