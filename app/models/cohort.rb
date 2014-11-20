class Cohort < ActiveRecord::Base
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  has_many :students
  has_many :attendance_records, through: :students
  has_many :assessments

  attr_accessor :importing_cohort_id

  before_create :import_assessments
  after_destroy :reassign_admin_current_cohorts

  def number_of_days_since_start
    last_date = Date.today <= end_date ? Date.today : end_date
    class_days_until(last_date)
  end

  def total_class_days
    class_days_until(end_date)
  end

  def number_of_days_left
    total_class_days - number_of_days_since_start
  end

  def progress_percent
    (number_of_days_since_start.to_f / total_class_days.to_f) * 100
  end

private

  def import_assessments
    unless @importing_cohort_id.blank?
      self.assessments = Cohort.find(@importing_cohort_id).deep_clone(include: { assessments: :requirements }).assessments
    end
  end

  def reassign_admin_current_cohorts
    Admin.where(current_cohort_id: self.id).update_all(current_cohort_id: Cohort.last.id)
  end

  def class_days_until(last_date)
    (start_date..last_date).select { |date| !date.saturday? && !date.sunday? }.count
  end
end
