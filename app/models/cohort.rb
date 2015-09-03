class Cohort < ActiveRecord::Base
  default_scope { order(:start_date) }
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  has_many :students
  has_many :attendance_records, through: :students
  has_many :code_reviews
  has_many :internships

  attr_accessor :importing_cohort_id

  before_create :import_code_reviews
  after_destroy :reassign_admin_current_cohorts

  def list_class_days
    (start_date..end_date).select { |date| date if !date.saturday? && !date.sunday? }
  end

  def number_of_days_since_start
    last_date = Time.zone.now.to_date <= end_date ? Time.zone.now.to_date : end_date
    class_dates_until(last_date).count
  end

  def total_class_days
    class_dates_until(end_date).count
  end

  def number_of_days_left
    total_class_days - number_of_days_since_start
  end

  def progress_percent
    (number_of_days_since_start.to_f / total_class_days.to_f) * 100
  end

  def class_dates_until(last_date)
    (start_date..last_date).select { |date| !date.friday? && !date.saturday? && !date.sunday? }
  end

  def internships_sorted_by_interest(current_student)
    if current_student
      internships.sort_by do |internship|
        rating = current_student.find_rating(internship)
        if rating
          rating.interest
        else
          '0'
        end
      end
    else
      internships.by_company_name
    end
  end

private

  def import_code_reviews
    unless @importing_cohort_id.blank?
      self.code_reviews = Cohort.find(@importing_cohort_id).deep_clone(include: { code_reviews: :objectives }).code_reviews
    end
  end

  def reassign_admin_current_cohorts
    Admin.where(current_cohort_id: self.id).update_all(current_cohort_id: Cohort.last.id)
  end
end
