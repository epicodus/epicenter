class Submission < ActiveRecord::Base
  default_scope { order(:updated_at) }
  scope :needing_review, -> { where(needs_review: true) }
  validates_presence_of :link
  validates :user_id, uniqueness: { scope: :assessment_id }

  belongs_to :user
  belongs_to :assessment
  has_many :reviews
  has_one :latest_review, -> { order('created_at DESC') }, class_name: "Review"

  before_create :mark_as_needing_review

  def has_been_reviewed?
    needs_review == false
  end

  def clone_or_build_review
    if latest_review
      latest_review.deep_clone(include: :grades)
    else
      Review.new(submission: self)
    end
  end

private

  def mark_as_needing_review
    self.needs_review = true
  end
end
