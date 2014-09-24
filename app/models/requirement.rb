class Requirement < ActiveRecord::Base
  validates_presence_of :content

  belongs_to :assessment
end
