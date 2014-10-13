# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cohort do
    description "Current cohort"
    start_date Date.today
    end_date Date.today + 15.weeks
  end
end
