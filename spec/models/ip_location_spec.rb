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

  describe '#is_local_computer_portland?' do
    it 'returns true if the computer is an epicodus computer in Portland' do
      expect(IpLocation.is_local_computer_portland?(ENV['SCHOOL_IP_ADDRESS'])).to eq true
    end

    it 'returns false if the computer is not an epicodus computer in Portland' do
      expect(IpLocation.is_local_computer_portland?(ENV['SEATTLE_WIFI_IP_ADDRESS'])).to eq false
    end
  end

  describe '#is_local_computer_seattle?' do
    it 'returns true if the computer is in the Seattle office' do
      expect(IpLocation.is_local_computer_seattle?(ENV['SEATTLE_WIFI_IP_ADDRESS'])).to eq true
    end

    it 'returns false if the computer is not in the Seattle office' do
      expect(IpLocation.is_local_computer_seattle?(ENV['SCHOOL_IP_ADDRESS'])).to eq false
    end
  end
end
