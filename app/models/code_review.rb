class CodeReview < ActiveRecord::Base
  default_scope { order(:number) }

  validates :title, presence: true
  validates :cohort, presence: true
  validate :presence_of_requirements

  has_many :requirements
  has_many :submissions
  belongs_to :cohort

  accepts_nested_attributes_for :requirements, reject_if: :attributes_blank?, allow_destroy: true

  before_create :set_number

  def submission_for(student)
    submissions.find_by(student: student)
  end

  def expectations_met_by?(student)
    submission_for(student).try(:meets_expectations?)
  end

  def latest_total_score_for(student)
    if submission_for(student).try(:has_been_reviewed?)
      requirements.inject(0) { |sum, requirement| sum += requirement.score_for(student) }
    else
      0
    end
  end

private

  def set_number
    self.number = cohort.code_reviews.pluck(:number).last.to_i + 1
  end

  def presence_of_requirements
    if requirements.size < 1
      errors.add(:requirements, 'must be present.')
    end
  end

  def attributes_blank?(attributes)
    attributes['content'].blank?
  end
end
