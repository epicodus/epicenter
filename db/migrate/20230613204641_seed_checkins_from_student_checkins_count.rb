class SeedCheckinsFromStudentCheckinsCount < ActiveRecord::Migration[7.0]
  def up
    admin = Admin.find_by(email: 'mike@epicodus.com') # since we don't know actual admin for past checkins
    Student.find_each do |student|
      student.checkins_legacy.times do
        Checkin.create!(student: student, admin: admin)
      end
    end
  end

  def down
    Checkin.each do |checkin|
      student = checkin.student
      checkins_count = student.checkins_legacy || 0
      student.update(checkins_legacy: checkins_count + 1)
    end
    Checkin.delete_all
  end
end
