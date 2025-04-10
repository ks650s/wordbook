class AddUserAnswerToFlashcardQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :flashcard_questions, :user_answer, :string
  end
end
