class AddCorrectCountToFlashcards < ActiveRecord::Migration[7.0]
  def change
    add_column :flashcards, :correct_count, :integer
  end
end
