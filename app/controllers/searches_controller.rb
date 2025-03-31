class SearchesController < ApplicationController
  def search
    # モデル選択
    @model = params["model"]
    # 検索欄入力内容
    @content = params["content"]
    @records = search_for(@model, @content)
  end
    
  private
    def search_for(model, content)
    # 選択したモデルがquestion(単語）だったら
    if model  == 'question'
      Question.where('title LIKE ? OR description LIKE ? ', '%'+content+'%', '%'+content+'%')
    # 選択したモデルがquestion_similar_word(類義語）だったら
    #elsif model  == 'question_similar_word'
    else
      QuestionSimilarWord.where('similar_word LIKE ?', '%'+content+'%')
      # Question_similar_word.where('similar_word LIKE ?', '%'+content+'%')
      # Question.where('similar_word LIKE ?', '%'+content+'%')
    end
  end 
end
