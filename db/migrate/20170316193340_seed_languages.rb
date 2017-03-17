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
    Course.where(parttime: true).update_all(language_id: Language.find_by(name: "Evening").id)
    Course.where('description LIKE ?', '%Intro%').where(parttime: false).update_all(language_id: Language.find_by(name: "Intro").id)
    Course.where('description LIKE ?', '%Ruby%').where(parttime: false).update_all(language_id: Language.find_by(name: "Ruby").id)
    Course.where('description LIKE ?', '%PHP%').where(parttime: false).update_all(language_id: Language.find_by(name: "PHP").id)
    Course.where('description LIKE ?', '%Java%').where(parttime: false).update_all(language_id: Language.find_by(name: "Java").id)
    Course.where('description LIKE ?', '%C#%').where(parttime: false).update_all(language_id: Language.find_by(name: "C#").id)
    Course.where('description LIKE ?', '%CSS%').where(parttime: false).update_all(language_id: Language.find_by(name: "CSS").id)
    Course.where('description LIKE ?', '%JavaScript%').where(parttime: false).update_all(language_id: Language.find_by(name: "JavaScript").id)
    Course.where('description LIKE ?', '%Rails%').update_all(language_id: Language.find_by(name: "Rails").id)
    Course.where('description LIKE ?', '%Drupal%').update_all(language_id: Language.find_by(name: "Drupal").id)
    Course.where('description LIKE ?', '%Android%').update_all(language_id: Language.find_by(name: "Android").id)
    Course.where('description LIKE ?', '%.NET%').update_all(language_id: Language.find_by(name: ".NET").id)
    Course.where('description LIKE ?', '%Design%').update_all(language_id: Language.find_by(name: "Design").id)
    Course.where('description LIKE ?', '%Internship%').update_all(language_id: Language.find_by(name: "Internship").id)
end

  def down
    Course.update_all(language_id: nil)
    Language.destroy_all
  end
end
