class Flashcard < ApplicationRecord
  has_many :quizzes

  #問題出題で必要だったため追記
  has_many :question_similar_words
  
  has_many :flashcard_questions
  has_many :questions, through: :flashcard_questions
end
