class Flashcard < ApplicationRecord
  #クイズセッション用モデル
  
  # has_many :quizzes
  belongs_to :user

  #問題出題で必要だったため追記
  has_many :question_similar_words
  
  has_many :flashcard_questions, dependent: :destroy
  has_many :questions, through: :flashcard_questions

  enum status: { in_progress: "in_progress", completed: "completed" }
end
