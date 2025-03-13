class QuestionsController < ApplicationController

  def show
    @question = Question.find(params[:id])
    @question_similar_words = @question.question_similar_words.find(params[:id])
  end
  def index
    @questions = Question.all.order(:id)
  end

  def new
    @question = Question.new
  end

  def create
    @question = Question.new(question_params)
    if @question.save
      redirect_to questions_path
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
    @question = Question.find(params[:id])
  end

  def update
    @question = Question.find(params[:id])
    if @question.update(question_params)
      redirect_to questions_path
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    Question.find(params[:id]).destroy
    redirect_to questions_path
  end

  private
  def question_params
    params.require(:question).permit(:title, :description)
  end
end
