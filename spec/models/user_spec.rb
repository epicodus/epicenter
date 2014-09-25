require 'rails_helper'

describe User do
  it { should validate_presence_of :name }
  it { should have_one :bank_account }
  it { should have_many :payments }
  it { should have_many :submissions }

  describe "last_assessment" do
    it "returns the last assessment completed by a student" do
      test_user = User.create(name: "test", password: "password", password_confirmation: "password", email: "test@test.com")
      ass1 = Assessment.create(title: "first", section: "first section", section_number: 1, url: "first.com")
      ass2 = Assessment.create(title: "second", section: "second section", section_number: 2, url: "second.com")
      ass3 = Assessment.create(title: "third", section: "third section", section_number: 3, url: "third.com")
      ass4 = Assessment.create(title: "unknown", section: "unknown section", url: "unknown.com")
      sub1 = Submission.create(link: "testone.com", user_id: test_user.id, assessment_id: ass1.id)
      sub2 = Submission.create(link: "testtwo.com", user_id: test_user.id, assessment_id: ass2.id)
      expect(test_user.last_assessment).to eq ass2
    end
  end
end

