class CreateInternships < ActiveRecord::Migration
  def change
    create_table :internships do |t|
      t.integer :company_id
      t.integer :cohort_id

      t.text    :description
      t.text    :ideal_intern
      t.boolean :clearance_required
      t.text    :clearance_description

      t.timestamps
    end
  end
end
