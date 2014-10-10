FactoryGirl.define do
  factory :assessment do
    title 'assessment title'
    section 'object oriented design'
    url 'http://learnhowtoprogram.com'

    factory :assessment_with_requirements do
      after(:create) do |assessment|
        4.times { create(:requirement, assessment: assessment) }
      end
    end
  end
end
