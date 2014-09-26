require 'rails_helper'

describe User do
  it { should validate_presence_of :name }
  it { should have_one :bank_account }
  it { should have_many :payments }

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
end

