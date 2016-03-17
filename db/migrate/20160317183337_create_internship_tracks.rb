class CreateInternshipTracks < ActiveRecord::Migration
  def change
    create_table :internship_tracks do |t|
      t.integer :internship_id
      t.integer :track_id
    end
  end
end
