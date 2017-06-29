class Enrollment < ApplicationRecord
  belongs_to :course
  belongs_to :student

  validates :course, presence: true
  validates :student, presence: true
  validates :student_id, uniqueness: { scope: :course_id }

  acts_as_paranoid

  after_destroy :really_destroy_if_withdrawn_before_attending, if: ->(enrollment) { Enrollment.with_deleted.exists?(enrollment.id) }
  after_real_destroy :update_starting_cohort_on_withdraw
  after_create :update_starting_cohort_on_enroll

private

  def update_starting_cohort_on_enroll
    old_start_date = student.starting_cohort_id ? Course.find(student.starting_cohort_id).start_date : nil
    if !course.parttime? && (!old_start_date || course.start_date < old_start_date)
      first_course = student.courses_with_withdrawn.fulltime_courses.first
      student.update(starting_cohort_id: first_course.try(:id))
    end
  end

  def update_starting_cohort_on_withdraw
    the_student = student || Student.with_deleted.find(student_id)
    if course_id == the_student.starting_cohort_id
      first_course = the_student.courses_with_withdrawn.fulltime_courses.first
      the_student.update(starting_cohort_id: first_course.try(:id))
    end
  end

  def really_destroy_if_withdrawn_before_attending
    if (Time.zone.now.to_date < course.start_date) || (student.attendance_records_for(:all, course) == 0 && course.language.level != 4)
      really_destroy!
    end
  end
end
