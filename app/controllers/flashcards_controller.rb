class FlashcardsController < ApplicationController

  def show
    #@flashcard = Flashcard.find(params[:id])
  end

  def new
    @flashcards = Question.select(:title)
    @flashcard = @flashcards.sample(1)
    #@flashcard = @flashcards.order("RAND()")
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
    question_similar_words_attributes: [:id, :similar_word, :_destroy])
  end
end