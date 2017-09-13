class Enrollment < ApplicationRecord
  belongs_to :course
  belongs_to :student

  validates :course, presence: true
  validates :student, presence: true
  validates :student_id, uniqueness: { scope: :course_id }

  acts_as_paranoid

  before_create :update_internship_class_in_crm, if: ->(enrollment) { enrollment.course.internship_course? }
  before_destroy :remove_internship_class_in_crm, if: ->(enrollment) { enrollment.course.internship_course? }
  after_destroy :really_destroy_if_withdrawn_before_attending, if: ->(enrollment) { Enrollment.with_deleted.exists?(enrollment.id) }
  after_real_destroy :update_starting_cohort_on_withdraw
  after_create :update_starting_cohort_on_enroll

private

  def update_starting_cohort_on_enroll
    old_cohort = Cohort.find_by_id(student.starting_cohort_id)
    new_cohort = course.cohorts.first if course.cohorts.count == 1
    if new_cohort && new_cohort != old_cohort # if it's a fulltime course being added AND course being added is in different cohort than student previously registered in
      if old_cohort.nil? || new_cohort.start_date < old_cohort.start_date
        student.update(starting_cohort_id: new_cohort.try(:id))
        student.update_close_io({ 'custom.Starting Cohort': new_cohort.try(:description) })
      end
    end
  end

  def update_starting_cohort_on_withdraw
    the_student = student || Student.with_deleted.find(student_id)
    old_cohort = Cohort.find_by_id(the_student.starting_cohort_id)
    if old_cohort && ((old_cohort.courses & the_student.courses_with_withdrawn) - [course]).empty? # last course unenrolled from cohort student registered in
      first_course = the_student.courses_with_withdrawn.fulltime_courses.first
      starting_cohort = first_course.try(:cohorts).try(:first)
      the_student.update(starting_cohort_id: starting_cohort.try(:id))
      the_student.update_close_io({ 'custom.Starting Cohort': starting_cohort.try(:description) })
    end
  end

  def really_destroy_if_withdrawn_before_attending
    if (Time.zone.now.to_date < course.start_date) || (student.attendance_records_for(:all, course) == 0 && course.language.level != 4)
      really_destroy!
    end
  end

  def update_internship_class_in_crm
    location = course.office.name
    location = 'PDX' if location == 'Portland'
    location = 'SEA' if location == 'Seattle'
    description = "#{location} #{course.description.split.first} #{course.start_date.strftime('%b %-d')} - #{course.end_date.strftime('%b %-d')}"
    crm_response = student.update_close_io({ ENV['CRM_INTERNSHIP_CLASS_FIELD'] => description })
    crm_response.try('field-errors').try(:values).try(:map) { |value| errors.add(:base, value) }
    throw :abort if errors.any?
  end

  def remove_internship_class_in_crm
    student.update_close_io({ ENV['CRM_INTERNSHIP_CLASS_FIELD'] => nil })
  end
end
