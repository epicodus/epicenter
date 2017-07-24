class Submission < ApplicationRecord
  default_scope { order(:updated_at) }
  scope :needing_review, -> { where(needs_review: true) }
  scope :for_course, ->(course) { joins(:code_review).where(code_reviews: { course_id: course }) }
  validates :link, presence: true, url: true, unless: ->(submission) { submission.code_review.try(:submissions_not_required?) }
  validates :student_id, uniqueness: { scope: :code_review_id }

  belongs_to :student
  belongs_to :code_review
  has_many :reviews
  has_many :notes

  accepts_nested_attributes_for :notes

  before_create :mark_as_needing_review
  before_save :update_times_submitted

  def has_been_reviewed?
    needs_review == false
  end

  def clone_or_build_review
    if latest_review
      latest_review.deep_clone(include: :grades)
    else
      review = Review.new(submission: self)
      code_review.objectives.each { |objective| review.grades.build(objective: objective) }
      review
    end
  end

  def latest_review
    reviews.order('created_at DESC').first
  end

  def meets_expectations?
    latest_review.try(:meets_expectations?)
  end

private

  def update_times_submitted
    if needs_review == true
      times_submitted.nil? ? self.times_submitted = 1 : self.times_submitted += 1
    end
  end

  def mark_as_needing_review
    self.needs_review = true
  end
end
