class Review < ActiveRecord::Base
  belongs_to :submission
  belongs_to :user
  has_many :grades

  validates :note, presence: true

  after_create :mark_submission_as_reviewed

  private

  def mark_submission_as_reviewed
    submission.update(needs_review: false)
  end
end
