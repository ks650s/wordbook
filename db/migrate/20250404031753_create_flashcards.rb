class CreateFlashcards < ActiveRecord::Migration[7.0]
  def change
    create_table :flashcards do |t|
      t.integer :correct
      t.integer :wrong

      t.timestamps
    end
  end
end
