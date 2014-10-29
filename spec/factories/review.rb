FactoryGirl.define do
  factory :review do
    note 'Great job!'
    submission

    after(:create) do |review|
      review.submission.assessment.requirements.each do |requirement|
        FactoryGirl.create(:grade, review: review, requirement: requirement)
      end
    end
  end
end
