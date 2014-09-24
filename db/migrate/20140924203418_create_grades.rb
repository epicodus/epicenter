class CreateGrades < ActiveRecord::Migration
  def change
    create_table :grades do |t|
      t.belongs_to :submission
      t.belongs_to :requirement
      t.string :comment
      t.integer :score

      t.timestamps
    end
  end
end
