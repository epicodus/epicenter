require 'rails_helper'

describe User do
  it { should validate_presence_of :name }
  it { should have_one :bank_account }
  it { should have_many :payments }
  it { should have_many :submissions }

  describe 'teachers' do
    it 'returns an array of users where "admin" = true' do
      teacher = FactoryGirl.create(:user, name: "Joe", admin: true)
      student = FactoryGirl.create(:user, name: "Sally", admin: false)
      expect(User.teachers.count).to eql 1
    end
  end

  describe 'students' do
    it 'returns an array of users where "admin" = true' do
      teacher = FactoryGirl.create(:user, name: "Joe", admin: true)
      student = FactoryGirl.create(:user, name: "Sally", admin: false)
      expect(User.students.count).to eql 1
    end
  end

  describe 'assessment_completion' do
    it 'returns the percentage of assessments completed' do
      student = FactoryGirl.create(:user, admin: false)
      assessment = FactoryGirl.create(:assessment)
      assessment2 = FactoryGirl.create(:assessment, title: "Ajax")
      submission = FactoryGirl.create(:submission, assessment_id: assessment2.id, graded: true, user_id: student.id)
      expect(student.assessment_completion).to eq 50
    end
  end

  describe 'grade_four' do
    it 'returns the count of four point grades for all submissions' do
      student = FactoryGirl.create(:user, admin: false)
      assessment = FactoryGirl.create(:assessment)
      submission = FactoryGirl.create(:submission, assessment_id: assessment.id, graded: true, user_id: student.id)
      grade = FactoryGirl.create(:grade, submission_id: submission.id, score: 4)
      grade2 = FactoryGirl.create(:grade, submission_id: submission.id, score: 4)
      expect(student.grade_four).to eq 2
    end
  end

  describe 'grade_three' do
    it 'returns the count of three point grades for all submissions' do
      student = FactoryGirl.create(:user, admin: false)
      assessment = FactoryGirl.create(:assessment)
      submission = FactoryGirl.create(:submission, assessment_id: assessment.id, graded: true, user_id: student.id)
      grade = FactoryGirl.create(:grade, submission_id: submission.id, score: 3)
      grade2 = FactoryGirl.create(:grade, submission_id: submission.id, score: 3)
      expect(student.grade_three).to eq 2
    end
  end

  describe 'grade_two' do
    it 'returns the count of two point grades for all submissions' do
      student = FactoryGirl.create(:user, admin: false)
      assessment = FactoryGirl.create(:assessment)
      submission = FactoryGirl.create(:submission, assessment_id: assessment.id, graded: true, user_id: student.id)
      grade = FactoryGirl.create(:grade, submission_id: submission.id, score: 2)
      grade2 = FactoryGirl.create(:grade, submission_id: submission.id, score: 2)
      expect(student.grade_two).to eq 2
    end
  end

  describe 'grade_one' do
    it 'returns the count of one point grades for all submissions' do
      student = FactoryGirl.create(:user, admin: false)
      assessment = FactoryGirl.create(:assessment)
      submission = FactoryGirl.create(:submission, assessment_id: assessment.id, graded: true, user_id: student.id)
      grade = FactoryGirl.create(:grade, submission_id: submission.id, score: 1)
      grade2 = FactoryGirl.create(:grade, submission_id: submission.id, score: 1)
      expect(student.grade_one).to eq 2
    end
  end

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

