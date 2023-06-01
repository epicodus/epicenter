describe Internship do
  it { should belong_to :company }
  it { should have_many :ratings }
  it { should have_many :interview_assignments }
  it { should have_many :internship_assignments }
  it { should have_many(:courses).through(:course_internships) }
  it { should have_many(:students).through(:ratings) }
  it { should validate_presence_of :courses }
  it { should validate_presence_of :description }
  it { should validate_presence_of :ideal_intern }
  it { should validate_presence_of :name }
  it { should validate_presence_of :website }
  it { should validate_presence_of :number_of_students }

  describe 'validations' do
    it 'returns false if an internship is saved with number_of_students not equal to 2, 4, or 6' do
      course = FactoryBot.create(:internship_course)
      internship = FactoryBot.build(:internship, courses: [course], number_of_students: 5)
      expect(internship.save).to eq false
    end
  end

  describe '#assigned_as_interview_for' do
    let(:assigned_internship) { FactoryBot.create(:internship) }
    let(:student) { FactoryBot.create(:student, courses: [assigned_internship.courses.first]) }

    it "returns internships that a student doesn't have assigned interviews with" do
      FactoryBot.create(:internship)
      FactoryBot.create(:interview_assignment, student_id: student.id, internship_id: assigned_internship.id)
      expect(Internship.assigned_as_interview_for(student)).to eq [assigned_internship]
    end
  end

  describe '#not_assigned_as_interview_for' do
    let(:internship) { FactoryBot.create(:internship) }
    let(:internship_2) { FactoryBot.create(:internship) }
    let(:student) { FactoryBot.create(:student, courses: [internship.courses.first, internship_2.courses.first]) }

    it "returns internships that a student doesn't have assigned interviews with" do
      FactoryBot.create(:interview_assignment, student_id: student.id, internship_id: internship.id)
      expect(Internship.not_assigned_as_interview_for(student)).to eq [internship_2]
    end
  end

  describe '#fix_url' do
    it 'strips whitespace from url' do
      internship = FactoryBot.create(:internship, website: 'http://www.test.com    ')
      expect(internship.website).to eq 'http://www.test.com'
    end

    it 'returns false with invalid url' do
      internship = FactoryBot.build(:internship, website: 'http://].com')
      expect(internship.save).to eq false
    end

    context 'with a valid uri scheme' do
      it "doesn't prepend 'http://' to the url when it starts with 'http:/" do
        internship = FactoryBot.create(:internship, website: 'http://www.test.com')
        expect(internship.website).to eq 'http://www.test.com'
      end
    end

    context 'with an invalid uri scheme' do
      it "prepends 'http://' to the url when it doesn't start with 'http" do
        internship = FactoryBot.create(:internship, website: 'www.test.com')
        expect(internship.website).to eq 'http://www.test.com'
      end
    end
  end

  describe 'other_internship_courses' do
    it 'returns all internship courses not associated with the internship' do
      internship = FactoryBot.create(:internship)
      other_internship_course = FactoryBot.create(:internship_course)
      expect(internship.other_internship_courses).to eq [other_internship_course]
    end
  end

  describe  '#formatted_number_of_students' do
    it 'returns formatted display for number of students' do
      internship = FactoryBot.create(:internship, number_of_students: 2)
      expect(internship.formatted_number_of_students).to eq '2-3'
      internship = FactoryBot.create(:internship, number_of_students: 4)
      expect(internship.formatted_number_of_students).to eq '4-5'
      internship = FactoryBot.create(:internship, number_of_students: 6)
      expect(internship.formatted_number_of_students).to eq '6+'
    end
  end

  describe  '#formatted_location' do
    it 'returns formatted display for location' do
      internship = FactoryBot.create(:internship, location: 'onsite')
      expect(internship.formatted_location).to eq 'on-site'
      internship = FactoryBot.create(:internship, location: 'remote')
      expect(internship.formatted_location).to eq 'remote'
      internship = FactoryBot.create(:internship, location: 'either')
      expect(internship.formatted_location).to eq 'on-site or remote'
    end
  end

  describe 'emails company internship update' do
    it 'on internship create' do
      allow(EmailJob).to receive(:perform_later).and_return({})
      internship = FactoryBot.create(:internship)
      email_body = "Hi #{internship.company.name}. This is confirmation that you have requested #{internship.formatted_number_of_students} interns from the following internship period(s): " + internship.courses.map {|c| c.description_and_office}.join(', ')
      expect(EmailJob).to have_received(:perform_later).with({ :from => ENV['FROM_EMAIL_REVIEW'], :to => internship.company.email, :subject => "Epicodus internship sign-up updated", :text => email_body })
    end

    it 'on internship update' do
      allow(EmailJob).to receive(:perform_later).and_return({})
      internship = FactoryBot.create(:internship)
      internship.update(number_of_students: 6)
      email_body = "Hi #{internship.company.name}. This is confirmation that you have requested 6+ interns from the following internship period(s): " + internship.courses.map {|c| c.description_and_office}.join(', ')
      expect(EmailJob).to have_received(:perform_later).with({ :from => ENV['FROM_EMAIL_REVIEW'], :to => internship.company.email, :subject => "Epicodus internship sign-up updated", :text => email_body })
    end
  end
end
