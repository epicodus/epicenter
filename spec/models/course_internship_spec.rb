describe CourseInternship do
  it { should validate_presence_of :course }
  it { should validate_presence_of :internship }

  describe 'validations' do
    it 'validates uniqueness of internship_id to course_id' do
      FactoryBot.create(:internship)
      FactoryBot.create(:course)
      should validate_uniqueness_of(:internship_id).scoped_to(:course_id)
    end
  end
end
