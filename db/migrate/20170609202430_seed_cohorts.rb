# Seeds all existing fulltime non-test courses into cohorts & tracks
# 2017-01 Portland PHP/Drupal [101, 130, 135, 136, 137]
# 2017-02 Portland Java/Android [115, 131, 149, 147, 144]
# 2017-03 Portland Ruby/Rails [116, 129, 160, 161, 145]
# 2017-04 Portland CSS/Design [117, 143, 172, 174, 170]
# 2017-04 Portland C#/.NET [118, 158, 173, 175, 170]
# 2017-05 Portland PHP/React [154, 183, 184, 187, 185]
# 2017-06 Portland Java/Android [156, 169]
# 2017-07 Portland Ruby/Rails [167, 182]
# 2017-09 Portland CSS/Design [178]
# 2017-09 Portland C#/.NET [179]
# 2017-10 Portland PHP/React [192]
# 2016-06 Seattle C#/.NET [56, 72, 76, 107, 97]
# 2016-08 Seattle C#/.NET [73, 79, 86, 90, 100]
# 2017-01 Seattle C#/.NET [104, 138, 139, 140, 141]
# 2017-02 Seattle PHP/Drupal [119, 150, 151, 152, 148]
# 2017-03 Seattle Ruby/Rails [120, 162, 163, 164, 165]
# 2017-05 Seattle Java/Android [155, 186, 188, 189, 190]
# 2017-06 Seattle C#/.NET [157, 194]
# 2017-07 Seattle Ruby/Rails [166]
# 2017-09 Seattle CSS/Design [180]
# 2017-10 Seattle Java/Android [193]
# 2016-01 Portland ALL [14, 15, 36, 44, 45, 46]
# 2016-01 Portland ALL [30, 29, 31, 27, 32, 25, 20, 34, 24, 37, 41, 40, 39, 50, 51, 49, 48, 47]
# 2016-03 Portland ALL [43, 42, 38, 53, 54, 60, 69, 70, 63]
# 2016-05 Portland ALL [55, 35, 57, 65, 59, 61, 75, 71, 83, 111, 84, 96]
# 2016-08 Portland ALL [52, 68, 110, 108, 81, 113, 80, 87, 114, 88, 95, 94, 93, 99]
# 2016-10 Portland ALL [77, 64, 91, 121, 92, 122, 123, 125, 126, 127, 128]
# 2016-08 Philadelphia PHP/Drupal [62, 78, 85, 89, 98]

class SeedCohorts < ActiveRecord::Migration
  def up
    cohorts.each do |cohort_data|
      Cohort.create_from_course_ids(cohort_data)
    end
  end

  def down
    cohorts.each do |cohort_data|
      cohort = Course.find(cohort_data[:courses].first).cohort
      cohort.courses.each do |course|
        course.cohort = nil
        course.track = nil
        course.save
      end
      cohort.destroy
    end
  end

  def cohorts
    [ { start_month: "2017-01", office: "Portland", track: "PHP/Drupal", courses: [101, 130, 135, 136, 137] }, { start_month: "2017-02", office: "Portland", track: "Java/Android", courses: [115, 131, 149, 147, 144] }, { start_month: "2017-03", office: "Portland", track: "Ruby/Rails", courses: [116, 129, 160, 161, 145] }, { start_month: "2017-04", office: "Portland", track: "CSS/Design", courses: [117, 143, 172, 174, 170] }, { start_month: "2017-04", office: "Portland", track: "C#/.NET", courses: [118, 158, 173, 175, 170] }, { start_month: "2017-05", office: "Portland", track: "PHP/React", courses: [154, 183, 184, 187, 185] }, { start_month: "2017-06", office: "Portland", track: "Java/Android", courses: [156, 169] }, { start_month: "2017-07", office: "Portland", track: "Ruby/Rails", courses: [167, 182] }, { start_month: "2017-09", office: "Portland", track: "CSS/Design", courses: [178] }, { start_month: "2017-09", office: "Portland", track: "C#/.NET", courses: [179] }, { start_month: "2017-10", office: "Portland", track: "PHP/React", courses: [192] }, { start_month: "2016-06", office: "Seattle", track: "C#/.NET", courses: [56, 72, 76, 107, 97] }, { start_month: "2016-08", office: "Seattle", track: "C#/.NET", courses: [73, 79, 86, 90, 100] }, { start_month: "2017-01", office: "Seattle", track: "C#/.NET", courses: [104, 138, 139, 140, 141] }, { start_month: "2017-02", office: "Seattle", track: "PHP/Drupal", courses: [119, 150, 151, 152, 148] }, { start_month: "2017-03", office: "Seattle", track: "Ruby/Rails", courses: [120, 162, 163, 164, 165] }, { start_month: "2017-05", office: "Seattle", track: "Java/Android", courses: [155, 186, 188, 189, 190] }, { start_month: "2017-06", office: "Seattle", track: "C#/.NET", courses: [157, 194] }, { start_month: "2017-07", office: "Seattle", track: "Ruby/Rails", courses: [166] }, { start_month: "2017-09", office: "Seattle", track: "CSS/Design", courses: [180] }, { start_month: "2017-10", office: "Seattle", track: "Java/Android", courses: [193] }, { start_month: "2016-01", office: "Portland", track: "ALL", courses: [14, 15, 36, 44, 45, 46] }, { start_month: "2016-01", office: "Portland", track: "ALL", courses: [30, 29, 31, 27, 32, 25, 20, 34, 24, 37, 41, 40, 39, 50, 51, 49, 48, 47] }, { start_month: "2016-03", office: "Portland", track: "ALL", courses: [43, 42, 38, 53, 54, 60, 69, 70, 63] }, { start_month: "2016-05", office: "Portland", track: "ALL", courses: [55, 35, 57, 65, 59, 61, 75, 71, 83, 111, 84, 96] }, { start_month: "2016-08", office: "Portland", track: "ALL", courses: [52, 68, 110, 108, 81, 113, 80, 87, 114, 88, 95, 94, 93, 99] }, { start_month: "2016-10", office: "Portland", track: "ALL", courses: [77, 64, 91, 121, 92, 122, 123, 125, 126, 127, 128] }, { start_month: "2016-08", office: "Philadelphia", track: "PHP/Drupal", courses: [62, 78, 85, 89, 98] } ]
  end
end
