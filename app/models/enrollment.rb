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
  after_create :update_cohort
  after_destroy :update_cohort

private

  def update_cohort
    new_starting_cohort = student.calculate_starting_cohort
    new_current_cohort = student.calculate_current_cohort
    new_parttime_cohort = student.calculate_parttime_cohort
    crm_update = {}
    if student.starting_cohort != new_starting_cohort
      student.update(starting_cohort: new_starting_cohort)
      crm_update = crm_update.merge({ 'custom.Cohort - Starting': new_starting_cohort.try(:description), 'custom.Start Date': new_starting_cohort.try(:start_date).try(:to_s) })
    end
    if student.cohort != new_current_cohort
      student.update(cohort: new_current_cohort)
      student.update(ending_cohort: new_current_cohort) unless new_current_cohort.nil?
      crm_update = crm_update.merge({ 'custom.Cohort - Current': new_current_cohort.try(:description), 'custom.End Date': new_current_cohort.try(:end_date).try(:to_s) })
    end
    if student.parttime_cohort != new_parttime_cohort
      student.update(parttime_cohort: new_parttime_cohort)
      student.update(ending_cohort: new_parttime_cohort) unless new_parttime_cohort.nil?
      crm_update = crm_update.merge({ 'custom.Cohort - Part-time': new_parttime_cohort.try(:description) })
    end
    student.crm_lead.update(crm_update) if crm_update.present?
  end

  def update_internship_class_in_crm
    student.crm_lead.update_internship_class(course)
  end

  def remove_internship_class_in_crm
    fallback_internship_course = (student.courses.internship_courses.order(:start_date) - [course]).last
    student.crm_lead.update_internship_class(fallback_internship_course)
  end

  def really_destroy_if_withdrawn_before_attending
    if (Time.zone.now.to_date < course.start_date.end_of_week) || (student.attendance_records_for(:all, course) == 0 && course.language.level != 4)
      really_destroy!
    end
  end
end
