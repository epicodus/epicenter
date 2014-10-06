require 'rails_helper'

describe AttendanceRecord do
  it { should belong_to :user }
  it { should validate_presence_of :user_id }

  it 'validates that an attendance record has not already been created for today' do
    user = FactoryGirl.create(:user)
    attendance_record = AttendanceRecord.create(user: user)
    another_attendance_record = AttendanceRecord.create(user: user)
    expect(another_attendance_record.valid?).to eq false
  end
end
