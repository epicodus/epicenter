desc "one-time use: add internship courses to existing pt full-stack cohorts"
task :tmp_add_internships_to_pt_cohorts => [:environment] do
  path = "https://github.com/epicodus-classroom/testing/blob/master/4_internship_layout.yaml"
  admin = Admin.find_by(name: "Cathy Bradley")
  language = Language.find_by(name: "Internship")
  track = Track.find_by(description: "Part-Time C#/React")
  track.cohorts.each do |cohort|
    course = Course.create(layout_file_path: path, admin: admin, track: track, language: language, office: cohort.office, start_date: cohort.end_date + 1.day)
    cohort.courses << course
    cohort.reload
    cohort.update(description: "#{cohort.start_date.to_s} to #{cohort.end_date.to_s} #{cohort.office.short_name} #{track.description}")
    cohort.students.each do |student|
      student.courses << course
      student.crm_lead.update({ Rails.application.config.x.crm_fields['COHORT_CURRENT'] => cohort.description })
    end
  end
end