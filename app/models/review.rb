class Review < ActiveRecord::Base
  belongs_to :submission
  belongs_to :admin
  has_one :student, through: :submission
  has_many :grades

  validates :note, presence: true

  accepts_nested_attributes_for :grades

  after_create :mark_submission_as_reviewed
  after_create :email_student

  def meets_expectations?
    grades.includes(:score).pluck(:value).all? { |value| value > 1 }
  end

private

  def mark_submission_as_reviewed
    submission.update(needs_review: false)
  end

  def email_student
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => ENV['FROM_EMAIL_REVIEW'],
        :to => student.email,
        :subject => "Assessment reviewed",
        :text => "Hi #{student.name}. Your #{submission.assessment.title} assessment has been reviewed. You can view it at #{Rails.application.routes.url_helpers.assessment_url(self.submission.assessment)}."
      }
    )
  end
end
