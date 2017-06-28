class SeedSubmissionNotes < ActiveRecord::Migration
  def up
    Submission.select {|submission| submission.blurb.present?}.each do |submission|
      note = submission.notes.new(content: submission.blurb, created_at: submission.updated_at)
      note.save(validate: false)
    end
    Submission.update_all(blurb: nil)
  end

  def down
    Submission.select {|submission| submission.notes.any?}.each {|submission| submission.update_columns(blurb: submission.notes.order(:created_at).last.try(:content))}
    Note.destroy_all
  end
end
