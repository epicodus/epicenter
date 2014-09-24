class Assessment < ActiveRecord::Base
  validates_presence_of :title, :section, :url
  has_many :submissions
  has_many :requirements
end
