describe Cohort do
  it { should have_many :students }
  it { should have_many(:attendance_records).through(:students) }
  it { should have_many :code_reviews }
  it { should have_many :internships}
  it { should validate_presence_of :description }
  it { should validate_presence_of :start_date }
  it { should validate_presence_of :end_date }

  describe '#attendance_for_today' do
    let(:cohort) { FactoryGirl.create(:cohort) }
    let(:student) { FactoryGirl.create(:student, cohort: cohort) }
    let(:student_2) { FactoryGirl.create(:student, cohort: cohort) }
    let(:attendance_record) { FactoryGirl.create(:attendance_record, student: student, date: Date.today) }
    let(:attendance_record_2) { FactoryGirl.create(:attendance_record, student: student_2, date: Date.today) }

    it "returns the cohort's attendance records for the current day" do
      expect(cohort.attendance_for_today).to eq [attendance_record, attendance_record_2]
    end
  end

  describe '#list_class_days' do
    let(:cohort) { FactoryGirl.create(:cohort) }

    it 'returns a list of class days with weekend days nil' do
      cohort.start_date = Date.new(2015, 8, 31)
      cohort.end_date = Date.new(2015, 9, 7)
      expect(cohort.list_class_days).to eq [cohort.start_date, cohort.start_date + 1, cohort.start_date + 2, cohort.start_date + 3, cohort.start_date + 4, cohort.start_date + 7]
    end
  end

  describe '#number_of_days_since_start' do
    let(:cohort) { FactoryGirl.create(:cohort) }

    it 'counts number of days since start of class' do
      travel_to cohort.start_date + 6.days do
        expect(cohort.number_of_days_since_start).to eq 4
      end
    end

    it 'does not count fridays or weekends' do
      travel_to cohort.start_date + 13.days do
        expect(cohort.number_of_days_since_start).to eq 8
      end
    end

    it 'does not count days after the class has ended' do
      travel_to cohort.end_date + 60.days do
        expect(cohort.number_of_days_since_start).to eq 60
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
      expect(cohort.total_class_days).to eq 8
    end
  end

  describe '#number_of_days_left' do
    it 'returns the number of days left in the cohort' do
      monday = Time.zone.now.to_date.beginning_of_week
      friday = monday + 4.days
      next_friday = friday + 1.week

      cohort = FactoryGirl.create(:cohort, start_date: monday, end_date: next_friday)
      travel_to friday do
        expect(cohort.number_of_days_left).to eq 4
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

  describe '#internships_sorted_by_interest' do
    let(:cohort) { FactoryGirl.create(:cohort) }
    let(:student) { FactoryGirl.create(:student, cohort: cohort) }
    let(:internship_one) { FactoryGirl.create(:internship, cohort: cohort) }
    let(:internship_two) { FactoryGirl.create(:internship, cohort: cohort) }

    it 'returns a list of internships sorted with higher interest first' do
      rating_one =  FactoryGirl.create(:rating, internship: internship_one, student: student, interest: '2')
      rating_two =  FactoryGirl.create(:rating, internship: internship_two, student: student, interest: '1')
      expect(cohort.internships_sorted_by_interest(student)).to eq([internship_two, internship_one])
    end

    it 'puts unrated internships at the beginning of the list' do
      internship_three = FactoryGirl.create(:internship, cohort: cohort)
      rating_one =  FactoryGirl.create(:rating, internship: internship_one, student: student, interest: '1')
      rating_two =  FactoryGirl.create(:rating, internship: internship_two, student: student, interest: '3')
      expect(cohort.internships_sorted_by_interest(student)).to eq([internship_three, internship_one, internship_two])
    end

    it 'returns internships sorted by company name when student is nil' do
      expect(cohort.internships_sorted_by_interest(nil)).to eq([internship_two, internship_one])
    end
  end
end
