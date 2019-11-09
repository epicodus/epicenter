class AddProbationToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :probation, :boolean
  end
end
