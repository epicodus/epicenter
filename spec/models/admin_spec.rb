describe Admin do
  it { should belong_to :current_cohort }

  describe '.escrow_balance' do
    it "returns the current escrow balance amount" do
      mine = double('mine')
      allow(Balanced::Marketplace).to receive(:mine) { mine }
      allow(mine).to receive(:in_escrow) { 21000 }
      expect(Admin.escrow_balance).to eq 21000
    end
  end

  describe '.transfer_full_escrow_balance' do
    it "does nothing if balance is zero" do
      mine = double('mine')
      allow(Balanced::Marketplace).to receive(:mine) { mine }
      allow(mine).to receive(:in_escrow) { 0 }

      owner_customer = double('owner_customer')
      allow(mine).to receive(:owner_customer) { owner_customer }

      Admin.transfer_full_escrow_balance

      expect(mine).to_not have_received(:owner_customer)
    end

    it "pays out the full escrow balance to the Balanced owner bank account" do
      mine = double('mine')
      allow(mine).to receive(:in_escrow) { 21000 }
      allow(Balanced::Marketplace).to receive(:mine) { mine }

      first = spy('first')
      allow(mine).to receive_message_chain(:owner_customer, :bank_accounts, :first).and_return(first)

      Admin.transfer_full_escrow_balance
      expect(first).to have_received(:credit).with(
        :amount => 21000,
        :description => 'Tuition payments withdrawal'
      )
    end
  end

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
      it { is_expected.to not_have_abilities([:create, :update], Payment.new) }
    end

    context 'for verifications', vcr: true do
      it { is_expected.to not_have_abilities(:update, Verification.new) }
    end

    context 'for cohorts' do
      it { is_expected.to have_abilities(:manage, Cohort.new) }
    end
  end

  it 'is assigned a default current_cohort before creation' do
    FactoryGirl.create(:cohort)
    admin = FactoryGirl.build(:admin, current_cohort: nil)
    admin.save
    expect(admin.current_cohort).to be_a Cohort
  end
end
