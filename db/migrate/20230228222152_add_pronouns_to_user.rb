class AddPronounsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :pronouns, :string
  end
end
