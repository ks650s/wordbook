class QuestionsController < ApplicationController
  before_action :require_login, only: [:show, :new, :create, :edit, :update, :destroy]

  require 'csv'

  def show
    @question = Question.find(params[:id])
    @question_similar_words = @question.question_similar_words.find(params[:id])
  end

  def index 
    @questions = Question.all.order(:id)
    respond_to do |format|
      format.html
      format.csv do |csv|
        send_questions_csv(@questions)
      end
    end
    
  end

  def new
    @question = Question.new
    #@question_similar_word = @question.question_similar_words.build
    #@question.question_similar_words.build
    # 類義語入力欄が二つ増えるのを防止する為
    1.times { @question.question_similar_words.build }
  end

  def create
    @question = current_user.questions.build(question_params)
    @question.image.attach(params[:question][:image])
    if @question.save
      redirect_to questions_path
    else
      puts @question.errors.full_messages
  @question.question_similar_words.each do |word|
    puts word.errors.full_messages
  end
  render :new
      #render 'new', status: :unprocessable_entity
    end
  end

  def edit
    @question = Question.find(params[:id])
  end

  def update
    @question = Question.find(params[:id])

    # 画像を新しく登録＆古いのを消さず、二つ登録されてしまう状況では古い画像が勝手に消える
    @question.image.purge if params[:remove_image] == "1"
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
    params.require(:question).permit(:user_id, :title, :description, :name, :image, tag_ids:[], 
    question_similar_words_attributes: [:id, :similar_word, :_destroy])
  end

end
