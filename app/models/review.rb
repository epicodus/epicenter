class Review < ActiveRecord::Base
  belongs_to :submission
  belongs_to :admin
  has_many :grades

  validates :note, presence: true

  accepts_nested_attributes_for :grades

  after_create :mark_submission_as_reviewed

  def meets_expectations?
    grades.includes(:score).pluck(:value).all? { |value| value > 1 }
  end

private

  def mark_submission_as_reviewed
    submission.update(needs_review: false)
  end
end
