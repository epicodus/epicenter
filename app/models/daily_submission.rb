class DailySubmission < ApplicationRecord
  belongs_to :student

  validates :link, presence: true
  validates :date, presence: true

  before_validation :remove_existing

private
  def remove_existing
    DailySubmission.where(student: student, date: date).destroy_all
  end
end
