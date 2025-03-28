class QuestionTag < ApplicationRecord
  belongs_to :question
  belongs_to :tag

  def self.looks(content)
    Question_similar_word.where("similar_word LIKE ?", '%'+content+'%')
  end
end
