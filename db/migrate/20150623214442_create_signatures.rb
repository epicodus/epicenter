class CreateSignatures < ActiveRecord::Migration
  def change
    create_table :signatures do |t|
      t.integer :student_id
      t.text :signature_request_id
      t.text :type
      t.boolean :is_complete
    end
  end
end
