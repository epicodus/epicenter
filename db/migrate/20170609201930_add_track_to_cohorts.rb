class AddTrackToCohorts < ActiveRecord::Migration
  def change
    add_reference :cohorts, :track, index: true, foreign_key: true
  end
end
