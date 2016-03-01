describe IpLocation do
  describe '#is_local?' do
    it 'returns true if the user is on a local authorized ip address' do
      expect(IpLocation.is_local?('::1')).to eq true
    end

    it 'returns false if the user is not local on a local authorized ip address' do
      expect(IpLocation.is_local?('50.203.165.90')).to eq false
    end
  end

  describe '#is_local_computer?' do
    it 'returns true if the computer is an epicodus computer' do
      expect(IpLocation.is_local_computer?('50.203.165.83')).to eq true
    end

    it 'returns false if the computer is not an epicodus computer' do
      expect(IpLocation.is_local_computer?('50.203.165.84')).to eq false
    end
  end
end
