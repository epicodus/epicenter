class RenameRequirementsToObjectives < ActiveRecord::Migration
  def change
    rename_table :requirements, :objectives
    rename_column :grades, :requirement_id, :objective_id
  end
end
