class AddNumberToObjectives < ActiveRecord::Migration[5.1]
  def change
    add_column :objectives, :number, :integer
  end
end
