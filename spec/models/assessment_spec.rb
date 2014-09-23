require 'rails_helper'

RSpec.describe Assessment, :type => :model do
  it { should validate_presence_of :title }
  it { should validate_presence_of :section }
  it { should validate_presence_of :url }
end
