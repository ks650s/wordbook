class CreateFlashcardQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :flashcard_questions do |t|

      t.timestamps
    end
  end
end
