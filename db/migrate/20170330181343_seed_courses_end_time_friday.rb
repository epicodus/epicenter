class SeedCoursesEndTimeFriday < ActiveRecord::Migration
  def up
    Course.fulltime_courses.level(1).update_all(end_time_friday: "12:00 PM")
    Course.fulltime_courses.level(2).update_all(end_time_friday: "12:00 PM")
    Course.fulltime_courses.level(3).update_all(end_time_friday: "12:00 PM")
  end

  def down
    Course.update_all(end_time_friday: nil)
  end
end
