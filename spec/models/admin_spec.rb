require 'rails_helper'

describe Admin do
  describe "abilities" do
    let(:admin) { FactoryGirl.create(:admin) }
    subject { Ability.new(admin) }

    it { is_expected.to be_able_to(:manage, :all) }
  end
end
