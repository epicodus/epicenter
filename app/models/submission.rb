class Submission < ActiveRecord::Base
  validates_presence_of :link

  belongs_to :user
  belongs_to :assessment
  has_many :reviews

  def has_been_reviewed?
    !reviews.empty?
  end
end
