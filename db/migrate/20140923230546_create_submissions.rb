class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.belongs_to :user
      t.string :link
      t.text :note
      t.belongs_to :assessment
    end
  end
end
