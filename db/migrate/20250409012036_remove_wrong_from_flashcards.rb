class RemoveWrongFromFlashcards < ActiveRecord::Migration[7.0]
  def change
    remove_column :flashcards, :wrong, :string
  end
end
