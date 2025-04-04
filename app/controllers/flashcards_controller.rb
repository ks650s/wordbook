class FlashcardsController < ApplicationController

  def show
    @flashcard = Flashcard.find(params[:id])
  end

  def new
    @flashcard = Flashcard.new
  end

  def index
    @flashcards = Flashcard.all.order(:id)
  end

  # 問題を10問回答／または中断した際に保存する
  def create
    @flashcard = Flashcard.new(flashcard_params)
      Question.where( 'id >= ?', rand(Question.first.id..Question.last.id) ).first
    if @flashcard.save
      redirect_to flashcards_path
    else
      render 'new', status: :unprocessable_entity
    end
  end

end