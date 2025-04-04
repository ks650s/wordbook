class Quiz < ApplicationRecord
  belongs_to :user
  has_many :questions through: :question_quizzes
end
