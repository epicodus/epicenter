class AddTrackToCourses < ActiveRecord::Migration
  def change
    add_reference :courses, :track, index: true, foreign_key: true
  end
end
