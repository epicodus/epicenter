class AddSignatureRequestIdToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :signature_request_id, :string
  end
end
