class FlashcardsController < ApplicationController

  def show
    #@flashcard = Flashcard.find(params[:id])
  end

  def new
    @answer = Flashcard.new
    #4/8朝
    #@flashcards = Question.pluck(:title)
    #@flashcard = @flashcards.sample(1).first

    # pluckでQuestionテーブルからidカラムを配列で取得→sampleでランダムに1つ取得→何故かfirstが無いとエラー
    # @flashcards = Question.pluck(:id).sample(1).first


    # pluckでQuestionテーブルからidカラムを配列で取得→sort_by{rand}で配列の値の順番ランダムに
    p @flashcards = Question.pluck(:id).sort_by{rand} 
    # firstで配列の一番目の値を取得
    p @flashcard = @flashcards.first
    # findでQuestionモデルから@flashcardのidと一致するデータを取得→変数@mondaiに入れる
    p @mondai = Question.find(@flashcard)
    # find_byでQuestionSimilarWordモデルのquestion_idと@flashcardのもつ(question_)idが一致するものを取得→変数@ruigigoに入れる
    p @ruigigo = QuestionSimilarWord.find_by(question_id: @flashcard)

    #間違った選択肢(description)
    p @wrongone = @flashcards.second
    p @answerwrongone = Question.find(@wrongone)
    p @wrongtwo = @flashcards.third
    p @answerwrongtwo = Question.find(@wrongtwo)

    p kaitou = [@mondai[:description], @answerwrongone[:description], @answerwrongtwo[:description]]
    p @kaitou = kaitou.sort_by{rand}
  end

  def create
  end

  def index
  end

  def destroy
  end


  private

  def flashcard_params
    params.require(:flashcard).permit(:user_id, :title, :description, :name, 
    question_similar_words_attributes: [:id, :similar_word])
  end
end