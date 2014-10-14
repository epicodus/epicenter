require 'rails_helper'

describe AttendanceRecord do
  include ActiveSupport::Testing::TimeHelpers
  it { should belong_to :user }
  it { should validate_presence_of :user_id }

  it 'validates that an attendance record has not already been created for today' do
    first_attendance_record = FactoryGirl.create(:attendance_record)
    second_attendance_record = FactoryGirl.build(:attendance_record, user: first_attendance_record.user)
    expect(second_attendance_record.valid?).to eq false
  end

  it 'is counted as tardy if the student checks in more than 2 minutes after the start of class' do
    travel_to Time.new(2015, 01, 05, 8, 55, 00)
    on_time_record = FactoryGirl.create(:attendance_record)
    travel 7.minutes
    tardy_record = FactoryGirl.create(:attendance_record)
    expect(on_time_record.tardy).to eq false
    expect(tardy_record.tardy).to eq true
  end
end
