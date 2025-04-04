class CreateQuestionQuizzes < ActiveRecord::Migration[7.0]
  def change
    create_table :question_quizzes do |t|
      t.string :question_id
      t.string :quiz_id

      t.timestamps
    end
  end
end
