class AddDemographicsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :demographics, :boolean
  end
end
