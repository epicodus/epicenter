class SignaturesController < ApplicationController
  protect_from_forgery except: [:create]

  def create
    response = JSON.parse(params['json'])
    event_type = response['event']['event_type']
    signature_request_id = response['signature_request']['signature_request_id']
    if event_type == 'signature_request_signed'
      signature = Signature.find_by(signature_request_id: signature_request_id)
      signature.update(is_complete: true)
      render json: { title: 'Hello API Event Received' }
    else
      render json: { title: 'Hello API Event Received' }
    end
  end
end
