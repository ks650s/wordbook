class FlashcardQuestion < ApplicationRecord
  belongs_to :flashcards
  belongs_to :questions
end
