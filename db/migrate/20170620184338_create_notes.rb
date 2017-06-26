class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.string :content
      t.references :submission, index: true, foreign_key: true

      t.timestamps
    end
  end
end
