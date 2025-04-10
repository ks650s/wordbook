class AddUserIdToFlashcards < ActiveRecord::Migration[7.0]
  def change
    add_reference :flashcards, :user, null: false, foreign_key: true
  end
end
