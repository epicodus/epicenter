class Checkin < ApplicationRecord
  belongs_to :student, class_name: 'User'
  belongs_to :admin, class_name: 'User'

  scope :week, ->(date = Date.today) { where('created_at BETWEEN ? AND ?', date.beginning_of_week(:saturday), date.end_of_week(:saturday) + 1.day) }
end
