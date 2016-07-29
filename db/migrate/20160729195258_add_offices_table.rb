class AddOfficesTable < ActiveRecord::Migration
  def change
    create_table(:offices) do |t|
      t.string :name

      t.timestamps
    end
  end
end
