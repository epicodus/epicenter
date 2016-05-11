class AddTimestampsToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :created_at, :datetime
    add_column :signatures, :updated_at, :datetime
  end
end
