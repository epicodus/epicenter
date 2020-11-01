class RemoveTimestampsFromTracks < ActiveRecord::Migration[5.2]
  def change
    remove_column :tracks, :created_at, :string
    remove_column :tracks, :updated_at, :string
  end
end
