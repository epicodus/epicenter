class Review < ApplicationRecord
  belongs_to :submission
  belongs_to :admin, optional: true
  has_one :student, through: :submission
  has_many :grades

  validates :note, presence: true
  validates :student_signature, presence: true

  accepts_nested_attributes_for :grades

  after_create :mark_submission_as_reviewed
  after_create :email_student
  after_save :update_submission_status

  def meets_expectations?
    grades.pluck(:value).all? { |value| value > 1 }
  end

private

  def mark_submission_as_reviewed
    submission.update(needs_review: false)
  end

  def update_submission_status
    review_status = meets_expectations? ? "pass" : "fail"
    submission.update(review_status: review_status)
  end

  def email_student
    EmailClient.create.send_message(
      ENV['MAILGUN_DOMAIN'],
      { :from => ENV['FROM_EMAIL_REVIEW'],
        :to => student.email,
        :subject => "Code review reviewed",
        :text => "Hi #{student.name}. Your #{submission.code_review.title} code has been reviewed. You can view it at #{Rails.application.routes.url_helpers.course_code_review_url(self.submission.code_review.course, self.submission.code_review)}."
      }
    )
  end
end
