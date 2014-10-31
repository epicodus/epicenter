require 'rails_helper'

describe Score do
  it { should validate_presence_of :value }
  it { should validate_presence_of :description }
end
