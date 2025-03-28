class QuestionSimilarWord < ApplicationRecord
  belongs_to :question

  def self.looks(content)
    @question_similar_word.where('similar_word LIKE ?', "%#{content}%")
  end
end
