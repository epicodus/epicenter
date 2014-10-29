class Submission < ActiveRecord::Base
  default_scope { order(:updated_at) }
  scope :needing_review, -> { where(needs_review: true) }
  validates_presence_of :link

  belongs_to :user
  belongs_to :assessment
  has_many :reviews
  has_one :latest_review, -> { order('created_at DESC') }, class_name: "Review"

  before_create :mark_as_needing_review

  def needs_review?
    needs_review
  end

  def has_been_reviewed?
    needs_review == false
  end

  private

  def mark_as_needing_review
    self.needs_review = true
  end
end
