describe Pairing do
  it { should belong_to(:attendance_record) }
  it { should belong_to(:pair).class_name('Student') }

  let(:student) { FactoryBot.create(:student) }
  let(:pair) { FactoryBot.create(:student) }
  let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, pairings_attributes: [pair_id: pair.id]) }

  it 'allows creation of pairings as nested attributes on attendance record' do
    expect(attendance_record.pairings.first.pair).to eq pair
  end

  it 'destroys pairs when destroying attendance record' do
    expect(Pairing.any?).to eq true
    attendance_record.destroy
    expect(Pairing.any?).to eq false
  end

  it "replaces pairings when updating attendance record with pair_ids" do
    new_pair = FactoryBot.create(:student)
    attendance_record.update(pair_ids: [new_pair.id])
    expect(attendance_record.pairings.count).to eq 1
    expect(attendance_record.pairings.first.pair).to eq new_pair
  end

  it "ignores duplicates and empty pair_id inputs" do
    new_pair = FactoryBot.create(:student)
    attendance_record.update(pair_ids: [new_pair.id, '', nil, new_pair.id])
    expect(attendance_record.pairings.count).to eq 1
    expect(attendance_record.pairings.first.pair).to eq new_pair
  end

  it "does not replace pairings when updating attendance record without pair_ids" do
    attendance_record.update(left_early: false)
    expect(attendance_record.pairings.first.pair).to eq pair
  end
end
