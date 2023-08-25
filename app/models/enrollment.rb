class Enrollment < ApplicationRecord
  belongs_to :course
  belongs_to :student

  validates :course, presence: true
  validates :student, presence: true
  validates :student_id, uniqueness: { scope: :course_id }

  acts_as_paranoid

  before_create :update_internship_class_in_crm, if: ->(enrollment) { enrollment.course.internship_course? }
  before_destroy :clear_submissions
  before_destroy :remove_internship_class_in_crm, if: ->(enrollment) { enrollment.course.internship_course? && !enrollment.deleted? }
  after_destroy :really_destroy_if_withdrawn_before_attending, if: ->(enrollment) { Enrollment.with_deleted.exists?(enrollment.id) }
  after_create :update_cohort, :update_transfers_count_in_crm
  after_destroy :update_cohort, :update_transfers_count_in_crm

  attr_reader :cohort_id

private

  def update_cohort
    student.parttime_cohort = student.calculate_parttime_cohort
    student.starting_cohort = student.calculate_starting_cohort
    student.cohort = student.calculate_current_cohort
    student.save if student.changed?
  end

  def update_transfers_count_in_crm
    student.crm_lead.update({ Rails.application.config.x.crm_fields['TRANSFERS'] => [student.enrolled_fulltime_cohorts.count - 1, 0].max })
  end

  def update_internship_class_in_crm
    student.crm_lead.update_internship_class(course)
  end

  def remove_internship_class_in_crm
    fallback_internship_course = (student.courses.internship_courses.order(:start_date) - [course]).last
    student.crm_lead.update_internship_class(fallback_internship_course)
  end

  def really_destroy_if_withdrawn_before_attending
    if (Time.zone.now.to_date < course.start_date.end_of_week) || (student.attendance_records_for(:all, course) == 0 && course.language.name != 'Internship')
      really_destroy!
    end
  end

  def clear_submissions
    student.submissions.where(code_review_id: course.code_reviews.pluck(:id)).update_all(needs_review: false)
  end
end
