class ChangeInternshipsRemoteToLocation < ActiveRecord::Migration[5.2]
  def change
    rename_column :internships, :remote, :location
  end
end
