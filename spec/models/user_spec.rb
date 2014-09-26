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

  describe ".students_by_assessment" do
    it "returns an array of hashes of data about students" do
      auser = User.create(name: "a", email: "a@a.com", password: "password", password_confirmation: "password", admin: false)
      buser = User.create(name: "b", email: "b@b.com", password: "password", password_confirmation: "password", admin: false)
      assessment1 = Assessment.create(title: "first", section: "1", url: "one.com", section_number: 1)
      assessment2 = Assessment.create(title: "second", section: "2", url: "two.com", section_number: 2)
      assessment3 = Assessment.create(title: "three", section: "3", url: "three.com", section_number: 3)
      submission1a = Submission.create(link: "submission.com", assessment_id: assessment1.id, user_id: auser.id)
      submission1b = Submission.create(link: "submission.com", assessment_id: assessment1.id, user_id: buser.id)
      submission2a = Submission.create(link: "submission.com", assessment_id: assessment2.id, user_id: auser.id)
      submission3b = Submission.create(link: "submission.com", assessment_id: assessment3.id, user_id: buser.id)
      result = {"first" => 0, "second" => 1, "three" => 1}
      expect(User.students_by_assessment).to eq result
    end
  end
end

