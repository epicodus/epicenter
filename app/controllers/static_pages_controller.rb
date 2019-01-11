class StaticPagesController < ApplicationController

  def show
    Rails.logger.info "REQUESTING_IP HTTP_CF_CONNECTING_IP: #{request.env['HTTP_CF_CONNECTING_IP']}"
    Rails.logger.info "REQUESTING_IP remote_ip: #{request.remote_ip}"
    Rails.logger.info "REQUESTING_IP HTTP_X_FORWARDED_FOR: #{request.env["HTTP_X_FORWARDED_FOR"].try(:split, ',').try(:first)}"
    Rails.logger.info "REQUESTING_IP REMOTE_ADDR: #{request.env["REMOTE_ADDR"]}"
    if IpLocation.is_local_computer_seattle?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      @queue_url = 'https://seattle-help.epicodus.com'
    else
      @queue_url = 'https://help.epicodus.com'
    end
  end
end
