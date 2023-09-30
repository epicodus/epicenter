class Checkin < ApplicationRecord
  belongs_to :student, class_name: 'User'
  belongs_to :admin, class_name: 'User'

  scope :week, ->(date = Date.today) { where(created_at: date.beginning_of_week(:saturday).beginning_of_day..(date.end_of_week(:saturday) + 1.day).end_of_day) }
end
