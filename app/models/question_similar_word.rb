class QuestionSimilarWord < ApplicationRecord
  belongs_to :question

  #問題出題で必要だったため追記
  belongs_to :flashcards
end
