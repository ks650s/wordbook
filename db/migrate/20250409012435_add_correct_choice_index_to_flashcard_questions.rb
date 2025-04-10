class AddCorrectChoiceIndexToFlashcardQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :flashcard_questions, :correct_choice_index, :integer
  end
end
