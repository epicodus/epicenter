class StaticPagesController < ApplicationController

  def show
    if IpLocation.is_local_computer_seattle?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      @queue_url = 'https://seattle-help.epicodus.com'
    else
      @queue_url = 'https://help.epicodus.com'
    end
  end
end
