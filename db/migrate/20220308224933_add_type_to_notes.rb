class AddTypeToNotes < ActiveRecord::Migration[5.2]
  def change
    add_column :notes, :type, :string
    Note.update_all(type: 'SubmissionNote')
  end
end
