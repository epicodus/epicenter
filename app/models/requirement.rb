class Requirement < ActiveRecord::Base
  validates_presence_of :content

  belongs_to :assessment
  has_many :grades

  def scores
    result = []
    [1, 2, 3, 4].each do |score|
      result << self.grades.where(score: score).count
    end
    result
  end
end
