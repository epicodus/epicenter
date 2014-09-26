require 'rails_helper'

RSpec.describe Requirement, :type => :model do
  it { should validate_presence_of :content }
  it { should belong_to :assessment }
  it { should have_many :grades }

  describe ".scores" do
    it "returns an array of the number of students who received a 1, 2, 3, or 4" do
      test_requirement = Requirement.create(content: "first req")
      grade1 = test_requirement.grades.create(score: 1)
      grade2 = test_requirement.grades.create(score: 2)
      grade3 = test_requirement.grades.create(score: 3)
      expect(test_requirement.scores).to eq [1, 1, 1, 0]
    end
  end
end
