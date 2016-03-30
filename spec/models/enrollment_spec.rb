describe Enrollment do
  it { should validate_presence_of :course }
  it { should validate_presence_of :student }

  describe 'validations' do
    it 'validates uniqueness of student_id to course_id' do
      student = FactoryGirl.create(:student)
      course = FactoryGirl.create(:course)
      Enrollment.create(student: student, course: course)
      should validate_uniqueness_of(:student_id).scoped_to(:course_id)
    end
  end

  describe 'checking student credits before enrolling' do
    let(:course_1) { FactoryGirl.create(:course) }
    let(:course_2) { FactoryGirl.create(:course) }
    let(:course_3) { FactoryGirl.create(:course) }
    let(:course_4) { FactoryGirl.create(:course) }
    let(:course_5) { FactoryGirl.create(:course) }
    let(:course_6) { FactoryGirl.create(:course) }

    it 'does not enroll a student if the student has run out of credits' do
      student = FactoryGirl.create(:student, courses: [course_1, course_2, course_3, course_4, course_5])
      enrollment = Enrollment.new(student_id: student.id, course_id: course_6.id)
      expect(enrollment.save).to be false
    end
  end
end
