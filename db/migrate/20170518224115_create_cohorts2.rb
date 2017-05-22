class CreateCohorts2 < ActiveRecord::Migration
  def change
    create_table :cohorts do |t|
      t.string :description
      t.date :start_date
      t.date :end_date
      t.belongs_to :office, index: true, foreign_key: true
    end
  end
end
