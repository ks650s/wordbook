class SearchesController < ApplicationController
  def search
    # モデル選択
    @model = params["model"]
    # 検索欄入力内容
    @content = params["content"]
    @records = search_for(@model, @content)
    # @model = params[:model]
    # @content = params[:content]
    # @records = search_for(@model, @content)

    #if @model == "Question"
      #@records = Question.looks(@content)
    #else
      #@records = Question_similar_word.looks(@content)
    #end
  end
    
  private
    def search_for(model, content)
    # 選択したモデルがquestion(単語）だったら
    if model  == 'question'
      Question.where('title LIKE ? OR description LIKE ? ', '%'+content+'%', '%'+content+'%')
    # 選択したモデルがquestion_similar_word(類義語）だったら
    elsif model  == 'question_similar_word'
      Question_similar_word.where('similar_word LIKE ?', '%'+content+'%')
    end
  end
end
