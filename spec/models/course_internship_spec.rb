describe CourseInternship do
  it { validate_presence_of :course }
  it { validate_presence_of :internship }

  describe "validates uniqueness of internship_id to course_id" do
    it do
      FactoryGirl.create(:internship)
      FactoryGirl.create(:course)
      should validate_uniqueness_of(:internship_id).scoped_to(:course_id)
    end
  end
end
