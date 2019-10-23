class SeedNumberOfWeeksForLanguages < ActiveRecord::Migration[5.2]
  def up
    Language.find_by(name: 'Evening').update(number_of_weeks: 10)
    Language.find_by(name: 'Intro').update(number_of_weeks: 3)
    Language.find_by(name: 'JavaScript').update(number_of_weeks: 4)
    Language.find_by(name: 'C# and .NET').update(number_of_weeks: 7)
    Language.find_by(name: 'Ruby and Rails').update(number_of_weeks: 7)
    Language.find_by(name: 'React').update(number_of_weeks: 6)
    Language.find_by(name: 'Internship').update(number_of_weeks: 7)
    Language.find_by(name: 'Intro (part-time track)').update(number_of_weeks: 6)
    Language.find_by(name: 'JavaScript (part-time track)').update(number_of_weeks: 7)
    Language.find_by(name: 'React (part-time track)').update(number_of_weeks: 11)
  end

  def down
  end
end
