class Enrollment < ApplicationRecord
  belongs_to :course
  belongs_to :student

  validates :course, presence: true
  validates :student, presence: true
  validates :student_id, uniqueness: { scope: :course_id }

  acts_as_paranoid

  before_create :update_internship_class_in_crm, if: ->(enrollment) { enrollment.course.internship_course? }
  before_destroy :remove_internship_class_in_crm, if: ->(enrollment) { enrollment.course.internship_course? && !enrollment.deleted? }
  after_destroy :really_destroy_if_withdrawn_before_attending, if: ->(enrollment) { Enrollment.with_deleted.exists?(enrollment.id) }
  after_create :update_cohort, unless: ->(enrollment) { enrollment.course.parttime? }
  after_destroy :update_cohort, unless: ->(enrollment) { enrollment.course.parttime? }

private

  def update_cohort
    if student.courses_with_withdrawn.fulltime_courses.empty?
      new_starting_cohort = nil
      new_ending_cohort = nil
    else
      first_course = student.courses_with_withdrawn.fulltime_courses.first
      last_course = student.courses_with_withdrawn.fulltime_courses.last
      new_starting_cohort = first_course.cohorts.first
      if last_course.cohorts.count > 1
        new_ending_cohort = student.courses.level(3).last.try(:cohorts).try(:first)
      else
        new_ending_cohort = last_course.cohorts.first
      end
    end

    crm_update = {}
    if student.starting_cohort != new_starting_cohort
      student.update(starting_cohort: new_starting_cohort)
      crm_update = crm_update.merge({ 'custom.Starting Cohort': new_starting_cohort.try(:description) })
    end
    if student.ending_cohort != new_ending_cohort
      student.update(ending_cohort: new_ending_cohort)
      crm_update = crm_update.merge({ 'custom.Ending Cohort': new_ending_cohort.try(:description) })
    end
    student.crm_lead.update(crm_update) if crm_update.present?
  end

  def update_internship_class_in_crm
    student.crm_lead.update_internship_class(course)
  end

  def remove_internship_class_in_crm
    fallback_internship_course = (student.courses.internship_courses - [course]).last
    student.crm_lead.update_internship_class(fallback_internship_course)
  end

  def really_destroy_if_withdrawn_before_attending
    if (Time.zone.now.to_date < course.start_date) || (student.attendance_records_for(:all, course) == 0 && course.language.level != 4)
      really_destroy!
    end
  end
end
