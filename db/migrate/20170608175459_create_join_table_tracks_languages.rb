class CreateJoinTableTracksLanguages < ActiveRecord::Migration
  def change
    create_join_table :tracks, :languages do |t|
      # t.index [:track_id, :language_id]
      # t.index [:language_id, :track_id]
    end
  end
end
