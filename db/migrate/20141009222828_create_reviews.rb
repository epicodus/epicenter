class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.belongs_to :submission
      t.belongs_to :user
      t.text :note

      t.timestamps
    end

    add_column :grades, :review_id, :integer
  end
end
