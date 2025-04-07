class Flashcard < ApplicationRecord
  has_many :quizzes
  
  has_many :flashcard_questions
  has_many :questions, through: :flashcard_questions
end
