class SeedLanguagesTracksJoinTable < ActiveRecord::Migration
  def up
    Track.all.each do |track|
      track.languages << Language.find_by(name: "Intro")
      track.languages << Language.find_by(name: track.description.split('/').first)
      track.languages << Language.find_by(name: "JavaScript")
      track.languages << Language.find_by(name: track.description.split('/').last)
      track.languages << Language.find_by(name: "Internship")
    end
  end

  def down
    Track.each { |track| track.languages = [] }
  end
end
