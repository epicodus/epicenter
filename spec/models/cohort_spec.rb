require 'rails_helper'

describe Cohort do
  it { should have_many :users }
  it { should have_many(:attendance_records).through(:users) }
  it { should validate_presence_of :description }
  it { should validate_presence_of :start_date }
  it { should validate_presence_of :end_date }

  describe '#number_of_days_since_start' do
    include ActiveSupport::Testing::TimeHelpers

    let(:cohort) { FactoryGirl.create(:cohort) }

    it 'counts number of days since start of class' do
      travel_to cohort.start_date + 6.days do
        expect(cohort.number_of_days_since_start).to eq 5
      end
    end

    it 'does not count weekends' do
      travel_to cohort.start_date + 13.days do
        expect(cohort.number_of_days_since_start).to eq 10
      end
    end

    it 'does not count days after the class has ended' do
      travel_to cohort.end_date + 60.days do
        expect(cohort.number_of_days_since_start).to eq 75
      end
    end
  end

  describe '.current' do
    include ActiveSupport::Testing::TimeHelpers

    it 'is the current cohort' do
      current_cohort = FactoryGirl.create(:cohort)
      past_cohort = FactoryGirl.create(:past_cohort)
      expect(Cohort.current).to eq current_cohort
    end
  end
end
