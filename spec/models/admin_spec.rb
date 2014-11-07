require 'rails_helper'

describe Admin do
  describe "abilities" do
    let(:admin) { FactoryGirl.create(:admin) }
    subject { Ability.new(admin) }

    context 'for assessments' do
      it { is_expected.to have_abilities(:manage, Assessment.new) }
    end

    context 'for submissions' do
      it { is_expected.to have_abilities(:read, Submission.new) }
      it { is_expected.to not_have_abilities([:create, :update], Submission.new) }
    end

    context 'for reviews' do
      it { is_expected.to have_abilities([:create], Review.new) }
    end

    context 'for cohort_attendance_statistics' do
      it { is_expected.to have_abilities(:read, CohortAttendanceStatistics) }
    end

    context 'for bank_accounts' do
      it { is_expected.to not_have_abilities(:create, BankAccount.new) }
    end

    context 'for credit_cards' do
      it { is_expected.to not_have_abilities(:create, CreditCard.new) }
    end

    context 'for payments', vcr: true do
      it { is_expected.to not_have_abilities(:create, Payment.new) }
      it { is_expected.to have_abilities(:read, Payment.new) }
    end

    context 'for verifications', vcr: true do
      it { is_expected.to not_have_abilities(:update, Verification.new) }
    end
  end
end
