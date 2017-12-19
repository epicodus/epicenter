class CreateSurveys < ActiveRecord::Migration[5.1]
  def change
    create_table :surveys do |t|
      t.string :name
      t.timestamps
    end

    create_table :survey_questions do |t|
      t.references :survey, foreign_key: true
      t.integer :number
      t.string :content
    end

    create_table :survey_options do |t|
      t.references :survey_question, foreign_key: true
      t.integer :number
      t.string :content
    end

    create_table :survey_responses do |t|
      t.integer :student_id, index: true
      t.integer :survey_question_id, index: true
      t.integer :survey_option_id, index: true
      t.string :explanation
      t.timestamps
    end

    add_column :users, :can_view_survey_results, :boolean
    add_column :code_reviews, :survey_id, :integer, index: true
  end
end
