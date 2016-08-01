class SeedCourseOfficeAssociation < ActiveRecord::Migration
  def up
    Course.update_all(office_id: Office.find_by(name: 'Portland').id)
    Course.find_by(description: '2016-06 Intro SEATTLE').update(office_id: Office.find_by(name: 'Seattle').id)
    Course.find_by(description: '2016-07 C# SEATTLE').update(office_id: Office.find_by(name: 'Seattle').id)
    Course.find_by(description: '2016-08 Intro SEATTLE').update(office_id: Office.find_by(name: 'Seattle').id)
    Course.find_by(description: '2016-08 Intro PHILLY').update(office_id: Office.find_by(name: 'Philadelphia').id)
  end

  def down
    Course.update_all(office_id: nil)
  end
end
