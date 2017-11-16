class AddShortNameToOffices < ActiveRecord::Migration[5.1]
  def change
    add_column :offices, :short_name, :string
  end
end
