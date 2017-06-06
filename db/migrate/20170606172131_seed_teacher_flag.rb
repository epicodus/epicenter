class SeedTeacherFlag < ActiveRecord::Migration
  def up
    Admin.find_by(email:"franz@epicodus.com").update(teacher: true)
    Admin.find_by(email:"leroi@epicodus.com").update(teacher: true)
    Admin.find_by(email:"lina@epicodus.com").update(teacher: true)
    Admin.find_by(email:"perry@epicodus.com").update(teacher: true)
    Admin.find_by(email:"tyler@epicodus.com").update(teacher: true)
    Admin.find_by(email:"elysia@epicodus.com").update(teacher: true)
    Admin.find_by(email:"john@epicodus.com").update(teacher: true)
    Admin.find_by(email:"loren@epicodus.com").update(teacher: true)
    Admin.find_by(email:"noah@epicodus.com").update(teacher: true)
    Admin.find_by(email:"jonathan@epicodus.com").update(teacher: true)
  end

  def down
    Admin.update_all(teacher: nil)
  end
end
