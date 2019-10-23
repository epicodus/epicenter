class AddArchivedToLanguages < ActiveRecord::Migration[5.2]
  def up
    add_column :languages, :archived, :boolean
    Language.where.not(id:Track.active.map(&:languages).flatten).where.not(id:20).each {|l| l.update(archived: true)}
  end

  def down
    remove_column :languages, :archived
  end
end
