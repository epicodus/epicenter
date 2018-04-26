class AddArchivedToTracks < ActiveRecord::Migration[5.1]
  def change
    add_column :tracks, :archived, :boolean
  end
end
