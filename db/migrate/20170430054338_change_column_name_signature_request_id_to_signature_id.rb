class ChangeColumnNameSignatureRequestIdToSignatureId < ActiveRecord::Migration
  def change
    rename_column :signatures, :signature_request_id, :signature_id
  end
end
