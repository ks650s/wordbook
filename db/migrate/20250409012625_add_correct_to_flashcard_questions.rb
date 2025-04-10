class AddCorrectToFlashcardQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :flashcard_questions, :correct, :boolean
  end
end
