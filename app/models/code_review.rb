class CodeReview < ActiveRecord::Base
  default_scope { order(:number) }

  validates :title, presence: true
  validates :cohort, presence: true
  validate :presence_of_objectives

  has_many :objectives
  has_many :submissions
  belongs_to :cohort

  accepts_nested_attributes_for :objectives, reject_if: :attributes_blank?, allow_destroy: true

  before_create :set_number

  def duplicate_code_review(cohort)
    copy_code_review = self.dup
    copy_code_review.cohort = cohort
    duplicate_objectives(copy_code_review)
    copy_code_review
  end

  def submission_for(student)
    submissions.find_by(student: student)
  end

  def expectations_met_by?(student)
    submission_for(student).try(:meets_expectations?)
  end

  def latest_total_score_for(student)
    if submission_for(student).try(:has_been_reviewed?)
      objectives.inject(0) { |sum, objective| sum += objective.score_for(student) }
    else
      0
    end
  end

private

  def duplicate_objectives(code_review)
    objectives.each do |objective|
      objective = objective.dup
      code_review.objectives.push(objective)
    end
  end

  def set_number
    self.number = cohort.code_reviews.pluck(:number).last.to_i + 1
  end

  def presence_of_objectives
    if objectives.size < 1
      errors.add(:objectives, 'must be present.')
    end
  end

  def attributes_blank?(attributes)
    attributes['content'].blank?
  end
end
