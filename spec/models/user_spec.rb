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
end

