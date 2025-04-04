class QuizzesController < ApplicationController
  def show
    @quiz = Quiz.find(params[:id])
  end

  def new
    @quiz = Quiz.new
  end

  def index
    @quizzes = Quiz.all.order(:id)
  end

  def create
    #ここで問題生成する
    @quizzes = Quiz.new(quiz_params)
    if @quiz.save
      redirect_to index_path
    else
      render 'new', status: :unprocessable_entity
    end
  end

  private
  def quiz_params
    params.require(:quiz).permit(:correct_answer, :finished_answer)
  end
end
