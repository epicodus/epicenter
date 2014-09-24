class CreateAssessmentRequirements < ActiveRecord::Migration
  def change
    create_table :assessment_requirements do |t|
      t.string :content
      t.belongs_to :assessment

      t.timestamps
    end
  end
end
