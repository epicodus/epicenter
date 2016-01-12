class CodeReview < ActiveRecord::Base
  default_scope { order(:number) }

  validates :title, presence: true
  validates :course, presence: true
  validate :presence_of_objectives

  has_many :objectives
  has_many :submissions
  belongs_to :course

  accepts_nested_attributes_for :objectives, reject_if: :attributes_blank?, allow_destroy: true

  before_create :set_number
  before_destroy :check_for_submissions

  def total_points_available
    objectives.length * 3
  end

  def duplicate_code_review(course)
    copy_code_review = self.deep_clone include: :objectives
    copy_code_review.course = course
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

  def check_for_submissions
    if submissions.any?
      errors.add(:base, 'Cannot delete a code review with existing submissions.')
      false
    end
  end

  def set_number
    self.number = course.code_reviews.pluck(:number).last.to_i + 1
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
