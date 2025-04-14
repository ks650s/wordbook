class SearchesController < ApplicationController
  def search
    # モデル選択
    @model = params["model"]
    # contentは検索欄入力内容
    @content = params["content"]
    # keywordsはタグ選択内容
    # &.は結果がnil時にエラーではなくnilを返す為の演算子
    # presentメソッドで存在するかどうか確認、存在する要素（nilではない）のみ返す
    # @keywordにはnilではない要素＝チェックしたタグのみ代入される
    @keywords = params["tag_ids"]&.select(&:present?)
    # recordsに全部入れる
    @records = search_for(@model, @content, @keywords)
  end

  # def searchtagflag
  #   @revealtag = params[:object_name]
  #   render partial: "form", locals: { revealtag: @revealtag }
  # end
  
    
  private
    def search_for(model, content, keywords)
    # 選択したモデルがquestion(単語）だったら
    if model  == 'question'
      Question.where('title LIKE ? OR description LIKE ? ', '%'+content+'%', '%'+content+'%')
    # 選択したモデルがquestion_similar_word(類義語）だったら
    #else
    elsif model == 'question_similar_word'
      QuestionSimilarWord.where('similar_word LIKE ?', '%'+content+'%')
    else
    # 選択したモデルがどちらでもない（タグ）だったら
    # タグ検索でチェックした要素がある場合
      if @keywords.present?
       # 一度@tag_wordを定義
        @tag_word = "タグ: "
       # タグは複数選択できるので、each文で一つずつ取得し "id" とする
        @keywords.each do |id|
          #@tag_word再定義。"id" に該当するタグ名を''スペースで区切って全て表示
          #if id != ""は結果表示に空を除外するif文（配列の先頭にidない空の値があるので)
          @tag_word = @tag_word + ' ' + Tag.find(id).name if id != ""
        end
        # .includesでQuestionモデルとQuestionTagモデルを結合し、Questionモデルのレコードに紐づくQuestionTagモデルのレコードを取得
        # .whereでquestion_tagsテーブルから、チェックを付けて検索対象としたタグのIDを持つレコードを検索
        Question.includes(:question_tags).where(question_tags: {tag_id: @keywords})
      end
    end
  end 
end
