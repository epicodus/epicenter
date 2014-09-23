# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :assessment do
    title "Some Title"
    section "Some Section"
    url "http://www.someurl.com"
  end
end
