class SeedTracksTable < ActiveRecord::Migration
  def up
    Track.create(description: 'Ruby/Rails')
    Track.create(description: 'PHP/Drupal')
    Track.create(description: 'Java/Android')
    Track.create(description: 'C#/.NET')
    Track.create(description: 'CSS/Design')
  end

  def down
    Track.destroy_all
  end
end
