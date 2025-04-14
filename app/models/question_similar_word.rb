class QuestionSimilarWord < ApplicationRecord
  belongs_to :question

  #問題出題で必要だったため追記
  #chatGPTによるといらないらしい 何故？
  belongs_to :flashcard, optional: true
end
