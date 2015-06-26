class SignaturesController < ApplicationController
  protect_from_forgery except: [:create]

  def new
  end

  def create
    response = JSON.parse(params['json'])
    event_type = response['event']['event_type']
    if event_type == 'signature_request_signed'
      signature_request_id = response['signature_request']['signature_request_id']
      signature = Signature.find_by(signature_request_id: signature_request_id)
      signature.update(is_complete: true)
    else
      render json: { title: 'Hello API Event Received' }
    end
  end
end
