require 'rails_helper'

describe AttendanceRecord do
  it { should belong_to :user }
  it { should validate_presence_of :user_id }

  it 'validates that an attendance record has not already been created for today' do
    first_attendance_record = FactoryGirl.create(:attendance_record)
    second_attendance_record = FactoryGirl.build(:attendance_record, user: first_attendance_record.user)
    expect(second_attendance_record.valid?).to eq false
  end
end
