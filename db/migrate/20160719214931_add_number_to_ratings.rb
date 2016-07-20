class AddNumberToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :number, :integer
  end
end
