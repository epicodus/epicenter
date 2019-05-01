class SeedNewTrackSchedule < ActiveRecord::Migration[5.2]
  def up
    Track.find_by(description: 'C#/React').update(description: 'C#/React old', archived: true)
    Track.find_by(description: 'Ruby/React').update(description: 'Ruby/React old', archived: true)
    c_track = Track.create(description: 'C#/React')
    ruby_track = Track.create(description: 'Ruby/React')

    intro = Language.find_by(name: 'Intro') # 5 weeks intro
    csharp_dotnet = Language.create(name: 'C# and .NET', level: 1, number_of_days: 34, skip_holiday_weeks: true) # 7 weeks back-end language
    ruby_rails = Language.create(name: 'Ruby and Rails', level: 1, number_of_days: 34, skip_holiday_weeks: true) # 7 weeks back-end language
    js = Language.create(name: 'JavaScript', level: 2, number_of_days: 10, skip_holiday_weeks: true) # 2 weeks JS
    react = Language.create(name: 'React', level: 3, number_of_days: 29, skip_holiday_weeks: true) # 6 weeks React
    internship = Language.find_by(name: 'Internship') # 7 weeks internship course

    c_track.languages = [intro, csharp_dotnet, js, react, internship]
    ruby_track.languages = [intro, ruby_rails, js, react, internship]
  end

  def down
    Track.find_by(description: 'C#/React').destroy
    Track.find_by(description: 'Ruby/React').destroy
    Track.find_by(description: 'C#/React old').update(description: 'C#/React')
    Track.find_by(description: 'Ruby/React old').update(description: 'Ruby/React')
  end
end
