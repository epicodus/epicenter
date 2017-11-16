class SeedParttimeCohorts < ActiveRecord::Migration[5.1]
  def up
    Course.parttime_courses.each do |course|
      admin = course.admin || Admin.find_by(name: "Michael")
      cohort = Cohort.create(office: course.office, admin: admin, track: course.track, start_date: course.start_date)
    end
  end

  def down
    Cohort.where(track: Track.find_by(description: 'Part-time')).destroy_all
  end
end
