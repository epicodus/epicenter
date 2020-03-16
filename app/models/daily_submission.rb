class DailySubmission < ApplicationRecord
  belongs_to :student

  validates :link, presence: true

  before_validation :set_date
  before_validation :remove_exsting

private
  def set_date
    self.date = Time.zone.now.to_date
  end

  def remove_exsting
    DailySubmission.where(student: student, date: date).destroy_all
  end
end
