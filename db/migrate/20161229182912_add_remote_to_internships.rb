class AddRemoteToInternships < ActiveRecord::Migration
  def change
    add_column :internships, :remote, :boolean
  end
end
