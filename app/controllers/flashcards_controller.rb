class FlashcardsController < ApplicationController
  #単語帳セッション一つを表示／個別の回答を見る使用
  def show
    @flashcard = Flashcard.find(params[:id])
  end


  # index(単語帳メインページ)で現在ログインしてるユーザーの過去セッションを並べる
  def index
    @flashcards = current_user.flashcards.includes(:flashcard_questions).order(created_at: :desc).paginate(page: params[:page], per_page: 5)
  end


  # 単語帳セッションを新しく始めるアクション(post)
  def start_session
    # Questionからランダムな順番で10件のレコードを取得
    questions = Question.order("RANDOM()").limit(10)
    # 現在ログイン中のユーザーに紐づくFlashcard を1件、空で作成し、保存
    # Userが親モデル、Flashcardが子モデル(アソシエーション)
    # .flashcardsは関連付きクエリ
    # create! なのでバリデーションに失敗したらエラー
    flashcard = current_user.flashcards.create!
  
    # セッションに保存パート
    # 10問のquestion_idを配列で保存（後で順番通りに出題）
    session[:flashcard_questions] = questions.map(&:id)
    # 回答を保存していくための空の配列（10個分） 
    session[:answers] = Array.new(10)
    # どの Flashcard にこのセッションが紐づいているかを記録
    # 回答終了時や中断時にこのidを使って保存する
    session[:current_flashcard_id] = flashcard.id 

    # question_session アクションへ画面遷移
    # index=0 → つまり「1問目」を表示することを意味する
    redirect_to question_session_flashcards_path(index: 0)
  end


  #Ajax対応版
  def question_session
    # セッションの「何問目」かをparams[:index]から受け取り、整数に変換して@indexに代入
    # 例: `/flashcards/question_session?index=2` のようなURLで3問目を出す
    @index = params[:index].to_i
    # セッションに保存された10問のquestion_idリスト（session[:flashcard_questions]）から、現在のインデックスの問題idを取得
    question_id = session[:flashcard_questions][@index]
    # question_idをもとにDBからその問題データを取得
    @question = Question.find(question_id)
    # 選択肢（意味）の選出　まずQuestionからidが@questionのidと一致しないもの(where.not)を二つ(limit)descriptionのカラム指定して取得
    # 正解に該当する選ばれた問題データのdescription取得する+足して配列の要素（正解含む3つのdescription）の順番をランダムに入れ替え
    @choices = (Question.where.not(id: @question.id).limit(2).pluck(:description) + [@question.description]).shuffle
    # そもそもsessionで「各問題に対してユーザーが何を選んだか」を配列の形で保存
    # session[:answers] = ["意味A", "意味B", nil, "意味C", ...]　session[:answers][1] → 2問目の回答(nilは未回答)
    # [@index]が今何問目かだから、これは「現在の問題に対するユーザーの回答（または 未回答nil）」
    @current_answer = session[:answers][@index]
    # 問題データの類義語からsimilar_wordカラムを取得
    @similar_words = @question.question_similar_words.pluck(:similar_word)
  
    # 通常遷移かAjaxかに応じて適切なレスポンスを返す部分
    respond_to do |format|
      format.html # 通常の画面遷移
      format.js   # question_session.js.erb を探し、JSで動的に問題を表示更新する（＝Ajax）
    end
  end
  
  
  # 中断した単語帳セッションを復元して再開
  def resume
    flashcard = current_user.flashcards.find(params[:id])
    flashcard_questions = flashcard.flashcard_questions.includes(:question)
  
    if flashcard_questions.empty?
      redirect_to start_session_flashcards_path, notice: "セッションが見つかりませんでした。"
      return
    end
  
    # 問題と回答を再構成
    session[:flashcard_questions] = flashcard_questions.map(&:question_id)
    session[:answers] = flashcard_questions.map(&:user_answer)
    session[:current_flashcard_id] = flashcard.id
  
    # 最初の未回答の問題に遷移（または最初に戻る）
    first_unanswered = session[:answers].index(nil) || 0
    redirect_to question_session_flashcards_path(index: first_unanswered)
  end


  #Ajax対応版
  def submit_session_answer
    index = params[:index].to_i
    answer = params[:answer]
    session[:answers][index] = answer if session[:answers]
  
    if index + 1 < session[:flashcard_questions].size
      @index = index + 1
      @question = Question.find(session[:flashcard_questions][@index])
      @choices = (Question.where.not(id: @question.id).limit(2).pluck(:description) + [@question.description]).shuffle
      @current_answer = session[:answers][@index]
      @similar_words = @question.question_similar_words.pluck(:similar_word)
  
      respond_to do |format|
        format.js   # submit_session_answer.js.erb を探す
      end
    else
      respond_to do |format|
        format.js { render js: "window.location.href='#{result_session_flashcards_path}'" }
      end
    end
  end


  # 単語帳セッション終了後の結果表示
  def result_session
    question_ids = session[:flashcard_questions]
    answers = session[:answers]
    flashcard_id = session[:current_flashcard_id]
    
    @results = []
    @correct_count = 0
    
    question_ids.each_with_index do |qid, i|
      question = Question.find(qid)
      correct = question.description
      user_answer = answers[i]
    
      is_correct = (user_answer == correct)
      @correct_count += 1 if is_correct
    
      @results << {
        question: question,
        correct: correct,
        your_answer: user_answer,
        correct_answered: is_correct
      }
    end
    
    # Flashcard に正解数を保存
    if flashcard_id
      flashcard = Flashcard.find_by(id: flashcard_id)
      flashcard.update(correct_count: @correct_count) if flashcard
     # すでに保存されていなければ保存する
     # 単語帳を最後まで終えた場合でも、各回答が flashcard_questions に保存されるようになる
      question_ids.each_with_index do |qid, i|
        answer = answers[i]
        FlashcardQuestion.find_or_initialize_by(flashcard: flashcard, question_id: qid).tap do |fq|
          fq.user_answer = answer
          fq.save!
        end
      end
    end
    
    @question_ids = question_ids
  end


  # 単語帳セッション中の「中断する」で単語帳セッション一覧に戻る
  def interrupt
    flashcard_id = session[:current_flashcard_id]
    return redirect_to flashcards_path, notice: "セッションがありません" unless flashcard_id

    flashcard = current_user.flashcards.find(flashcard_id)
    question_ids = session[:flashcard_questions]
    answers = session[:answers]

    question_ids.each_with_index do |question_id, index|
      answer = answers[index]
      FlashcardQuestion.find_or_initialize_by(flashcard: flashcard, question_id: question_id).tap do |fq|
        fq.user_answer = answer
        fq.save!
      end
    end
    # 中断後はセッションをクリア
    session[:flashcard_questions] = nil
    session[:answers] = nil
    session[:current_flashcard_id] = nil

    redirect_to flashcards_path, notice: "中断しました。"
  end


  # 「回答を見る」から遷移し、過去のセッションの記録だけを表示
  # result_session と似てるが、DB保存済みの FlashcardQuestion ベース
  def result
    flashcard = current_user.flashcards.find(params[:id])
    flashcard_questions = flashcard.flashcard_questions.includes(:question)
  
    @results = flashcard_questions.map do |fq|
      {
        question: fq.question,
        your_answer: fq.user_answer,
        correct: fq.question.description,
        correct_answered: fq.user_answer == fq.question.description
      }
    end
  
    @correct_count = @results.count { |r| r[:correct_answered] }
    @total_count = @results.size
  end


  #「もう一度やる」ボタンで回答情報だけリセットする
  def reset
    flashcard = Flashcard.find(params[:id])

    # 出題された問題IDを取得してセッションを再設定
    question_ids = flashcard.flashcard_questions.order(:created_at).map(&:question_id)

    session[:flashcard_questions] = question_ids
    session[:answers] = Array.new(question_ids.size)
    session[:current_flashcard_id] = flashcard.id

    # 回答情報を初期化（保存している場合）
    flashcard.flashcard_questions.update_all(user_answer: nil)

    redirect_to question_session_flashcards_path(index: 0, flashcard_id: flashcard.id)
  end


  # Rankingページ用
  def ranking
    # 完了済みセッションのみ取得
    # correct_count が nil ではない(.where.not) = 採点済みのセッション
    completed_flashcards = Flashcard.where.not(correct_count: nil)
  
    # ユーザーごとにセッション数と正解数を集計し、user_statsに
    # .group(:user_id)で採点済みセッションをuser_id＝ユーザーごとにまとめる
    # .select
    user_stats = completed_flashcards.group(:user_id).select(
      # グループ化のキー（ユーザーごと）を結果に含める
      :user_id,
      # 採点済みセッションの正解数の合計(SUM)をtotal_correctという名前で取得
      'SUM(correct_count) AS total_correct',
      # COUNT(*)は取得された行の数を返す=採点済みのセッションの数 をsession_countという名前で取得
      'COUNT(*) AS session_count'
    )
    # ↑SQLとして見ると
    #SELECT user_id, SUM(correct_count) AS total_correct, COUNT(*) AS session_count
    #FROM flashcards
    #WHERE correct_count IS NOT NULL
    #GROUP BY user_id

    # こうゆうイメージのオブジェクトの配列が今user_statsに
    #[<#ActiveRecord object user_id: 1, total_correct: 27, session_count: 3>,
    # <#ActiveRecord object user_id: 2, total_correct: 13, session_count: 2>]


    # 全ユーザーの情報を一括取得（処理を良くするため必要）
    # user_statsの中のuser_idを.map(&:user_id)で取り出し、.where(id: [...])で対象ユーザーのレコードをまとめて取得
    users = User.where(id: user_stats.map(&:user_id))
    # 毎回User.findしない為にシンボルで指定した値(:id)をキーにハッシュ化
    user_map = users.index_by(&:id)
  

    # 正解率計算 + ソート
    # それぞれのstatは「ある1人のユーザーの正解数とセッション数」に関する情報
    # .mapで1人ずつ処理して、必要な情報を持ったハッシュに整形
    @rankings = user_stats.map do |stat|
      {
        # 該当ユーザーを取得
        user: user_map[stat.user_id], #User.find(stat.user_id)
        # 正解数...SQLでSUM(correct_count)した値を.to_i して整数化
        total_correct: stat.total_correct.to_i,
        # 合計問題数...セッション数×10　これも.to_i して整数化
        total_questions: stat.session_count.to_i * 10,
        # 正解率(%)...total_correct.to_fで整数から小数へ（計算結果で小数点出す為）
        # .round(2)で小数点2位まで表示
        # 例: (74/18*10)*100=7400/180=41.11(%)
        accuracy: (stat.total_correct.to_f / (stat.session_count.to_i * 10) * 100).round
      }
    # ハッシュを正解率の高い順にソート（降順）ここでは:accuracyをキーにしている
    end.sort_by { |r| -r[:accuracy] }
  
    # 現在のユーザーの成績と順位（viewで使う）
    if current_user
      # @rankingsからuserキーの値がcurrent_userと一致する要素（＝ログイン中のユーザーの成績)を探す
      current_user_data = @rankings.find { |r| r[:user] == current_user }
      # 順位用...indexメソッドで正解率順に整理されたハッシュ@rankingsの中からログインしてるユーザー（要素）を探したい
      # 要素が最初の要素から何番目にあるのか整数で返る＝順位が分かる（+1するのはインデックス番号0から始まるから）
      @user_rank = @rankings.index(current_user_data) + 1 if current_user_data
      @user_data = current_user_data
    end
  end
  
end

  

    
  # def show
  #   @flashcard = Flashcard.find(params[:id])
  # end

  # def new
  #   @answer = Flashcard.new
  #    pluckでQuestionテーブルからidカラムを配列で取得→sort_by{rand}で配列の値の順番ランダムに
  #   @flashcards = Question.pluck(:id).sort_by{rand} 
  #    firstで配列の一番目の値を取得
  #   @flashcard = @flashcards.first
  #    findでQuestionモデルから@flashcardのidと一致するデータを取得→変数@mondaiに入れる
  #   @mondai = Question.find(@flashcard)
  #    find_byでQuestionSimilarWordモデルのquestion_idと@flashcardのもつ(question_)idが一致するものを取得→変数@ruigigoに入れる
  #   @ruigigo = QuestionSimilarWord.find_by(question_id: @flashcard)

  #   間違った選択肢(description)
  #   @wrongone = @flashcards.second
  #   @answerwrongone = Question.find(@wrongone)
  #   @wrongtwo = @flashcards.third
  #   @answerwrongtwo = Question.find(@wrongtwo)

  #   kaitou = [@mondai[:description], @answerwrongone[:description], @answerwrongtwo[:description]]
  #   @kaitou = kaitou.sort_by{rand}
  # end



  # private

  # def flashcard_params
  #   params.require(:flashcard).permit(:user_id, :title, :description, :name, 
  #   question_similar_words_attributes: [:id, :similar_word])
  # end
  # end
