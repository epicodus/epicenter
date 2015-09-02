module SignatureUpdater
  def update_signature_request
    if params.has_key?(:signature_request_id)
      signature = Signature.find_by(signature_request_id: params[:signature_request_id])
      signature.try(:update, is_complete: true)
    end
  end
end
