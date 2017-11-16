class SeedPartTimeTrack < ActiveRecord::Migration[5.1]
  def up
    track = Track.create(description: 'Part-time')
    track.languages << Language.find_by(name: 'Evening')
    Course.where('description LIKE ?', '%Evening%').each { |course| track.courses << course }
  end

  def down
    Track.find_by(description: 'Part-time').destroy
  end
end
