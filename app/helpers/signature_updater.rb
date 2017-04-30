module SignatureUpdater
  def update_signature_request
    if params.has_key?(:signature_id)
      signature = Signature.find_by(signature_id: params[:signature_id])
      signature.try(:update, is_complete: true)
    end
  end
end
