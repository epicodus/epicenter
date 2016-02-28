describe Ticket do
  it { should validate_presence_of :student_names }
  it { should validate_presence_of :note }
  it { should validate_presence_of :course_id }
  it { should validate_presence_of :location }
  it { should belong_to :course }

  describe '#other_open_tickets' do
    let(:existing_ticket_1) { FactoryGirl.create(:ticket) }
    let(:existing_ticket_2) { FactoryGirl.create(:ticket) }
    let(:new_ticket) { FactoryGirl.create(:ticket) }

    it 'returns all open tickets excluding the current ticket' do
      expect(new_ticket.other_open_tickets).to eq [existing_ticket_1, existing_ticket_2]
    end
  end
end
