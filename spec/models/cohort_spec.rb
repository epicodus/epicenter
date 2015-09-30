describe Cohort do
  it { should have_many :students }
  it { should have_many(:attendance_records).through(:students) }
  it { should have_many :code_reviews }
  it { should have_many :internships}

  describe "validates presence of attributes" do
    it "validates the presence of description" do
      cohort = FactoryGirl.build(:cohort, description: nil)
      expect(cohort).to_not be_valid
    end

    it "validates the presence of start_date" do
      cohort = FactoryGirl.build(:cohort, class_days: nil)
      expect(cohort.start_date).to eq nil
    end

    it "validates the presence of end_date" do
      cohort = FactoryGirl.build(:cohort, class_days: nil)
      expect(cohort.end_date).to eq nil
    end
  end

  describe "sets start and end dates from class_days" do
    let(:cohort) { FactoryGirl.create(:cohort) }

    it "returns a valid start date when set_start_and_end_dates is successful" do
      expect(cohort.start_date).to eq cohort.class_days.first
    end

    it "returns a valid end date when set_start_and_end_dates is successful" do
      expect(cohort.end_date).to eq cohort.class_days.last
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
      cohort = FactoryGirl.create(:cohort, class_days: (Time.zone.now.to_date..(Time.zone.now.to_date + 2.weeks - 1.day)).select { |day| day if !day.friday? && !day.saturday? && !day.sunday? })
      expect(cohort.total_class_days).to eq 8
    end
  end

  describe '#number_of_days_left' do
    it 'returns the number of days left in the cohort' do
      monday = Time.zone.now.to_date.beginning_of_week
      friday = monday + 4.days
      next_friday = friday + 1.week

      cohort = FactoryGirl.create(:cohort, class_days: (monday..next_friday).select { |day| day if !day.friday? && !day.saturday? && !day.sunday? })
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

      cohort = FactoryGirl.create(:cohort, class_days: (monday..next_friday).select { |day| day if !day.friday? && !day.saturday? && !day.sunday? })
      travel_to friday do
        expect(cohort.progress_percent).to eq 50.0
      end
    end
  end

  describe 'default scope order' do
    it 'orders the cohort by start date by default' do
      cohort = FactoryGirl.create(:cohort, class_days: [Date.new(2015, 1, 1), Date.new(2015, 1, 2)])
      cohort2 = FactoryGirl.create(:cohort, class_days: [Date.new(2014, 1, 1), Date.new(2014, 1, 2)])
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
