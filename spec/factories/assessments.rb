FactoryGirl.define do
  factory :assessment do
    title 'assessment title'
    section 'object oriented design'
    url 'http://learnhowtoprogram.com'

    before(:create) do |assessment|
      4.times { assessment.requirements << build(:requirement) }
    end
  end
end
