class SeedPtFullStackTrack < ActiveRecord::Migration[5.2]
  def change
    pt_c_track = Track.create(description: 'Part-Time C#/React')
    pt_intro_track = Track.find_by(description: 'Part-Time Intro to Programming')

    intro = Language.create(name: 'Intro (part-time track)', level: 0)
    js = Language.create(name: 'JavaScript (part-time track)', level: 1)
    csharp_dotnet = Language.create(name: 'C# and .NET (part-time track)', level: 2)
    react = Language.create(name: 'React (part-time track)', level: 3)

    pt_c_track.languages = [intro, js, csharp_dotnet, react]
    pt_intro_track.languages = [intro]
  end
end
