class SeedNewParttimeTrack < ActiveRecord::Migration[5.2]
  def up
    intro = Language.create(name: 'Intro (part-time track)', level: 0, number_of_days: 18, skip_holiday_weeks: true) # 6 week intro
    js = Language.create(name: 'JavaScript (part-time track)', level: 1, number_of_days: 21, skip_holiday_weeks: true) # 7 week js
    react = Language.create(name: 'React (part-time track)', level: 2, number_of_days: 33, skip_holiday_weeks: true) # 11 week react
    track = Track.create(description: 'Part-Time JS/React')
    track.languages = [intro, js, react]
  end

  def down
    Track.find_by(description: 'Part-Time JS/React').destroy
    Language.find_by(name: 'Intro (part-time track)').destroy
    Language.find_by(name: 'JavaScript (part-time track)').destroy
    Language.find_by(name: 'React (part-time track)').destroy
  end
end
