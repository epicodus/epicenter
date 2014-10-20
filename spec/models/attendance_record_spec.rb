require 'rails_helper'

describe AttendanceRecord do
  it { should belong_to :user }
  it { should validate_presence_of :user_id }

  describe 'uniqueness validation for users' do
    it 'validates that an attendance record for a user has not already been created for today' do
      first_attendance_record = FactoryGirl.create(:attendance_record)
      second_attendance_record = FactoryGirl.build(:attendance_record, user: first_attendance_record.user)
      expect(second_attendance_record.valid?).to eq false
    end

    it 'allows multiple users to check in on a single day' do
      first_user = FactoryGirl.create(:user)
      second_user = FactoryGirl.create(:user)
      first_attendance_record = FactoryGirl.create(:attendance_record, user: first_user)
      second_attendance_record = FactoryGirl.build(:attendance_record, user: second_user)
      expect(second_attendance_record.valid?).to eq true
    end
  end

  describe '.today' do
    include ActiveSupport::Testing::TimeHelpers

    it 'returns all the attendance records for today' do
      past_attendance_record = FactoryGirl.create(:attendance_record)
      travel_to Date.today + 1.day do
        current_attendance_record = FactoryGirl.create(:attendance_record)
        expect(AttendanceRecord.today).to eq [current_attendance_record]
      end
    end
  end

  describe '#tardy' do
    include ActiveSupport::Testing::TimeHelpers

    it 'is true if the student checks in after the start of class' do
      travel_to Time.new(2015, 01, 05, 9, 30, 00) do
        tardy_attendance_record = FactoryGirl.create(:attendance_record)
        expect(tardy_attendance_record.tardy).to eq true
      end
    end

    it 'is true if the student checks in after the start of class' do
      travel_to Time.new(2015, 01, 05, 8, 55, 00) do
        on_time_attendance_record = FactoryGirl.create(:attendance_record)
        expect(on_time_attendance_record.tardy).to eq false
      end
    end
  end
end
