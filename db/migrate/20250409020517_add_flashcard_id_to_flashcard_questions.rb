class AddFlashcardIdToFlashcardQuestions < ActiveRecord::Migration[7.0]
  def change
    add_reference :flashcard_questions, :flashcard, null: false, foreign_key: true
  end
end
