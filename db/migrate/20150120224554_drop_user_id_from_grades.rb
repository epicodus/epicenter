class DropUserIdFromGrades < ActiveRecord::Migration
  def change
    remove_column :grades, :user_id, :integer
  end
end
