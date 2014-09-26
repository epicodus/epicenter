class AddUserIdToGrades < ActiveRecord::Migration
  def change
    add_column :grades, :user_id, :integer
  end
end
