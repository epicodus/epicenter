class CreateAssessments < ActiveRecord::Migration
  def change
    create_table :assessments do |t|
      t.string :title
      t.string :section
      t.string :url

      t.timestamps
    end
  end
end
