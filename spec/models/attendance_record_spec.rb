require 'rails_helper'

describe AttendanceRecord do
  it { should belong_to :user }
  it { should validate_presence_of :user_id }

  it 'validates that an attendance record has not already been created for today' do
    first_attendance_record = FactoryGirl.create(:attendance_record)
    second_attendance_record = FactoryGirl.build(:attendance_record, user: first_attendance_record.user)
    expect(second_attendance_record.valid?).to eq false
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
