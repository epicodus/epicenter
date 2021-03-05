class AddHiringToInternships < ActiveRecord::Migration[5.2]
  def change
    add_column :internships, :hiring, :string
  end
end
