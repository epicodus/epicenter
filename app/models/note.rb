class Note < ActiveRecord::Base
  belongs_to :submission
  validates :content, presence: true, length: { maximum: 2000 }
end
