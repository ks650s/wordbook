class Question < ApplicationRecord
  has_many :question_tags
  has_many :question_similar_words
  has_many :tags, through: :question_tags
end
