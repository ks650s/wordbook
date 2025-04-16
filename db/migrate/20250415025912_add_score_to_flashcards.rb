class AddScoreToFlashcards < ActiveRecord::Migration[7.0]
  def change
    add_column :flashcards, :score, :integer
  end
end
