describe Cohort do
  it { should have_many :students }
  it { should have_many(:attendance_records).through(:students) }
  it { should have_many :code_reviews }
  it { should have_many :internships}
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

  describe '#class_dates_until' do
    let(:cohort) { FactoryGirl.create(:cohort) }

    it 'returns a collection of date objects for the class days up to a given date' do
      day_one = cohort.start_date
      day_two = day_one + 1.day
      travel_to day_two do
        expect(cohort.class_dates_until(day_two)).to eq [day_one, day_two]
      end
    end
  end

  describe '#total_class_days' do
    it 'counts the days of class minus weekends' do
      cohort = FactoryGirl.create(:cohort, start_date: Time.zone.now.to_date, end_date: (Time.zone.now.to_date + 2.weeks - 1.day))
      expect(cohort.total_class_days).to eq 10
    end
  end

  describe '#number_of_days_left' do
    it 'returns the number of days left in the cohort' do
      monday = Time.zone.now.to_date.beginning_of_week
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
      monday = Time.zone.now.to_date.beginning_of_week
      friday = monday + 4.days
      next_friday = friday + 1.week

      cohort = FactoryGirl.create(:cohort, start_date: monday, end_date: next_friday)
      travel_to friday do
        expect(cohort.progress_percent).to eq 50.0
      end
    end
  end

  describe 'default scope order' do
    it 'orders the cohort by start date by default' do
      cohort = FactoryGirl.create(:cohort, start_date: '2015-01-01', end_date: '2015-01-02')
      cohort2 = FactoryGirl.create(:cohort, start_date: '2014-01-01', end_date: '2014-01-01')
      expect(Cohort.all).to eq [cohort2, cohort]
    end
  end

  context 'after_destroy' do
    let(:cohort) { FactoryGirl.create(:cohort) }

    it 'reassigns all admins that have this as their current cohort to a different cohort' do
      another_cohort = FactoryGirl.create(:cohort)
      admin = FactoryGirl.create(:admin, current_cohort: cohort)
      cohort.destroy
      admin.reload
      expect(admin.current_cohort).to eq another_cohort
    end
  end
end
