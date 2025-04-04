require 'csv'

class QuestionsController < ApplicationController
  before_action :logged_in_user
  before_action :correct_user, only: [:edit, :update, :destroy]

  require 'csv'

  def show
    @question = Question.find(params[:id])
    # @question_similar_words = @question.question_similar_words.find(params[:id])
  end

  def index
    @questions = Question.all.order(:id)
    respond_to do |format|
      format.html
      format.csv do |csv|
        send_questions_csv(@questions)
      end
    end
    @question_similar_words = QuestionSimilarWord.all.order(:id)
  end

  def new
    @question = Question.new
    @question_similar_word = @question.question_similar_words.build
  end

  def create
    @question = Question.new(question_params)
    @question.image.attach(params[:question][:image])
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

  def send_questions_csv(questions)
    csv_data = CSV.generate do |csv|
      header = %w(id "単語" "意味")
      csv << header

      questions.each do |question|
        values = [question.id, question.title, question.description]
        csv << values
      end

    end
    send_data(csv_data, filename: "questions.csv")
  end


  private

  def question_params
    params.require(:question).permit(:title, :description, :name, :image, tag_ids:[], 
    question_similar_words_attributes: [:id, :similar_word, :_destroy])
  end

  # ログイン済みユーザーかどうか確認
  def logged_in_user
    unless logged_in?
      flash[:danger] = "Please log in."
      redirect_to login_url, status: :see_other
    end
  end

  # 正しいユーザーかどうか確認
  def correct_user
    
  end
end
