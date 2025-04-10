class FlashcardQuestion < ApplicationRecord
  belongs_to :flashcard
  belongs_to :question
end
