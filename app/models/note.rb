class Note < ApplicationRecord
  belongs_to :submission, optional: true
  belongs_to :student, optional: true
  validates :content, presence: true, length: { maximum: 2000 }
end
