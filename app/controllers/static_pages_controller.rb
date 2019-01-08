class StaticPagesController < ApplicationController

  def show
    Rails.logger.info "Requesting IP HTTP_CF_CONNECTING_IP: #{request.env['HTTP_CF_CONNECTING_IP']}"
    Rails.logger.info "Requesting IP remote_ip: #{request.remote_ip}"
    if IpLocation.is_local_computer_seattle?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      @queue_url = 'https://seattle-help.epicodus.com'
    else
      @queue_url = 'https://help.epicodus.com'
    end
  end
end
