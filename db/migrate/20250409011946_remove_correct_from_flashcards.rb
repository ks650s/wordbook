class RemoveCorrectFromFlashcards < ActiveRecord::Migration[7.0]
  def change
    remove_column :flashcards, :correct, :string
  end
end
