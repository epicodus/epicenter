class IpLocation

  def self.is_local?(ip)
    ip = IPAddr.new(ip)
    local_ip_ranges = ["::1", ENV['SCHOOL_IP_ADDRESS'], ENV['SCHOOL_WIFI_IP_ADDRESS'], ENV['SEATTLE_WIFI_IP_ADDRESS'], ENV['PHILADELPHIA_WIFI_IP_ADDRESS']]
    local_ip_ranges.any? { |range| IPAddr.new(range).include?(ip) }
  end

  def self.is_local_computer?(ip)
    IPAddr.new(ip) == ENV['SCHOOL_IP_ADDRESS'] || IPAddr.new(ip) == ENV['SEATTLE_WIFI_IP_ADDRESS'] || IPAddr.new(ip) == ENV['PHILADELPHIA_WIFI_IP_ADDRESS'] || IPAddr.new(ip) == "::1"
  end

  def self.is_local_computer_portland?(ip)
    IPAddr.new(ip) == ENV['SCHOOL_IP_ADDRESS']
  end

  def self.is_local_computer_seattle?(ip)
    IPAddr.new(ip) == ENV['SEATTLE_WIFI_IP_ADDRESS']
  end
end
