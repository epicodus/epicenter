# one-time task - for full-time students currently enrolled in just 1 course of their cohort, enroll them in the rest
desc "enroll partially-enrolled students in remainder of cohort"
task :enroll_students_in_remainder_of_cohort => [:environment] do
  students = []
  Cohort.future_cohorts.each do |cohort|
    cohort.courses.each do |course|
      course.students.each do |student|
        students << student if student.courses.fulltime_courses.count == 1
      end
    end
  end
  students.each do |student|
    cohort = student.courses.fulltime_courses.first.cohorts.first
    cohort.courses.each do |course|
      if student.courses.parttime_courses.any?
        student.courses << course if course.language.level >= 2
      else
        student.courses << course if course.language.level >= 1
      end
    end
  end
end
