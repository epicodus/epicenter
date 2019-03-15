class RenamePartTimeTrack < ActiveRecord::Migration[5.2]
  def up
    Track.find_by(description: 'Part-time').update(description: 'Part-Time Intro to Programming')
  end

  def down
    Track.find_by(description: 'Part-Time Intro to Programming').update(description: 'Part-time')
  end
end
