RSpec::Matchers.define :have_submit_button do |value|
  match do |actual|
    expect(actual).to have_selector("input[type=submit][value='#{value}']")
  end
end
