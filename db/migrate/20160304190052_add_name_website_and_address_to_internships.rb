class AddNameWebsiteAndAddressToInternships < ActiveRecord::Migration
  def change
    add_column :internships, :name, :string
    add_column :internships, :website, :string
    add_column :internships, :address, :string
  end
end
