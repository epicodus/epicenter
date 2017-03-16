class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.string :name
      t.integer :level
    end

    add_column :courses, :language_id, :integer
  end
end
