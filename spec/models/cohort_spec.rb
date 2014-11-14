describe Cohort do
  it { should have_many :students }
  it { should have_many(:attendance_records).through(:students) }
  it { should have_many :assessments }
  it { should validate_presence_of :description }
  it { should validate_presence_of :start_date }
  it { should validate_presence_of :end_date }

  describe '#number_of_days_since_start' do
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

  describe '#total_class_days' do
    it 'counts the days of class minus weekends' do
      cohort = FactoryGirl.create(:cohort, start_date: Date.today, end_date: (Date.today + 2.weeks - 1.day))
      expect(cohort.total_class_days).to eq 10
    end
  end

  describe '#number_of_days_left' do
    it 'returns the number of days left in the cohort' do
      monday = Date.today.beginning_of_week
      friday = monday + 4.days
      next_friday = friday + 1.week

      cohort = FactoryGirl.create(:cohort, start_date: monday, end_date: next_friday)
      travel_to friday do
        expect(cohort.number_of_days_left).to eq 5
      end
    end
  end

  describe '#progress_percent' do
    it 'returns the percent of how many days have passed' do
      monday = Date.today.beginning_of_week
      friday = monday + 4.days
      next_friday = friday + 1.week

      cohort = FactoryGirl.create(:cohort, start_date: monday, end_date: next_friday)
      travel_to friday do
        expect(cohort.progress_percent).to eq 50.0
      end
    end
  end

  describe '.current' do
    it 'is the current cohort' do
      current_cohort = FactoryGirl.create(:cohort)
      past_cohort = FactoryGirl.create(:past_cohort)
      expect(Cohort.current).to eq current_cohort
    end
  end
end
