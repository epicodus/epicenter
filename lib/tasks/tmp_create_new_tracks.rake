desc "create new tracks"
task :tmp_create_new_tracks => [:environment] do
  Language.active.find_by(name: 'Ruby and Rails').update(archived: true)
  Language.active.find_by(name: 'Ruby and Rails (part-time track)').update(archived: true)
  Track.active.find_by(description: 'C#/React').update(archived: true)
  Track.active.find_by(description: 'Part-Time C#/React').update(archived: true)

  ft_track = Track.create(description: 'C#/React')
  intro = Language.active.find_by(name: 'Intro', level: 0)
  js = Language.create(name: 'Intermediate JavaScript', level: 1)
  react = Language.create(name: 'React', level: 2)
  c = Language.create(name: 'C# and .NET', level: 3)
  capstone = Language.active.find_by(name: 'Capstone', level: 4)
  internship = Language.active.find_by(name: 'Internship', level: 5)
  ft_track.languages = [intro, js, react, c, capstone, internship]

  pt_track = Track.create(description: 'Part-Time C#/React')
  intro = Language.active.find_by(name: 'Intro (part-time track)', level: 0)
  js = Language.create(name: 'Intermediate JavaScript (part-time track)', level: 1)
  react = Language.create(name: 'React (part-time track)', level: 2)
  c = Language.create(name: 'C# and .NET (part-time track)', level: 3)
  capstone = Language.create(name: 'Capstone (part-time track)', level: 4)
  internship = Language.active.find_by(name: 'Internship', level: 5)
  pt_track.languages = [intro, js, react, c, capstone, internship]
end
