module SignatureParamsHelper
  def check_signature_params
    if params.has_key?(:sig_id)
      signature = Signature.find_by(signature_request_id: params[:sig_id])
      signature.update(is_complete: true)
    end
  end
end
