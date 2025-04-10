class AddQuestionIdToFlashcardQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :flashcard_questions, :question_id, :integer
  end
end
