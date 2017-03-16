class SeedLanguages < ActiveRecord::Migration
  def up
    Language.create(name: "Evening", level: 0)
    Language.create(name: "Intro", level: 0)
    Language.create(name: "Ruby", level: 1)
    Language.create(name: "PHP", level: 1)
    Language.create(name: "Java", level: 1)
    Language.create(name: "C#", level: 1)
    Language.create(name: "CSS", level: 1)
    Language.create(name: "JavaScript", level: 2)
    Language.create(name: "Rails", level: 3)
    Language.create(name: "Drupal", level: 3)
    Language.create(name: "Android", level: 3)
    Language.create(name: ".NET", level: 3)
    Language.create(name: "Design", level: 3)
    Language.create(name: "Internship", level: 4)
  end

  def down
    Language.destroy_all
  end
end
