class AddNumberOfWeeksToLanguages < ActiveRecord::Migration[5.2]
  def up
    add_column :languages, :number_of_weeks, :integer
  end

  def down
    remove_column :languages, :number_of_weeks
  end
end
