class FlashcardsController < ApplicationController
  before_action :require_login, only: [:show, :index, :start_session, :question_session,
                                      :submit_session_answer, :result_session, 
                                      :result, :reset, :ranking, :resume]

  #単語帳セッション一つを表示／個別の回答を見る使用
  def show
    @flashcard = Flashcard.find(params[:id])
  end


  # index(単語帳メインページ)で現在ログインしてるユーザーの過去セッションを並べる
  # 作成時間（降順）かつページネーション
  def index
    @flashcards = current_user.flashcards.includes(:flashcard_questions).order(created_at: :desc).paginate(page: params[:page], per_page: 5)
  end


  # 単語帳セッションを新しく始めるアクション(post)
  def start_session
    # Questionからランダムな順番で10件のレコードを取得
    questions = Question.all.sample(10)
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
    # 選択肢を保存していく為の空のハッシュ（後で3個入る）
    session[:choices] = {}
    # 出題する10問の Question を1問ずつ処理（index は何問目かを表す0〜9の番号）
    questions.each_with_index do |question, index|
      incorrect_choices = Question.where.not(id: question.id) # 正解と同じ問題（idで判別）を除外
                                  .order("RANDOM()") # ランダム並び替え
                                  .limit(2) # 二つ取得
                                  .pluck(:description) # そこから意味だけ取得
      # ランダムな不正解の意味二つ+正解の意味をシャッフルし、その問題（index番）の選択肢をセッションに保存。
      session[:choices][index.to_s] = (incorrect_choices + [question.description]).shuffle
    end

    # どの Flashcard にこのセッションが紐づいているかを記録
    # 回答終了時や中断時にこのidを使って保存する
    session[:current_flashcard_id] = flashcard.id 

    # question_session アクションへ画面遷移
    # index=0 → つまり「1問目」を表示することを意味する
    redirect_to question_session_flashcards_path(index: 0)
  end


  # 問題出題(Ajax対応版)
  def question_session
    
    # 選択肢保存ハッシュがfalseや未定義だったら空のハッシュになる
    session[:choices] ||= {}

    # セッションの「何問目」かをparams[:index]から受け取り、整数に変換して@indexに代入
    # 例: `/flashcards/question_session?index=2` のようなURLで3問目を出す
    @index = params[:index].to_i
    # セッションに保存された10問のquestion_idリスト（session[:flashcard_questions]）から、現在のインデックスの問題idを取得
    question_id = session[:flashcard_questions][@index]
    # question_idをもとにDBからその問題データを取得
    @question = Question.find(question_id)
  
    # 現在の問題（@index番目）に対して、すでに選択肢がセッションに保存されているかを確認
    # 例：2問目（@index = 1）の場合 → session[:choices]["1"] あれば再生成しない
    # .to_sで文字列化させてる理由は、sessionが文字列キーのハッシュなので整数のまま（@index）だとキーを見つけられない
    if session[:choices][@index.to_s].present?
      # セッションに既にある選択肢を変数@choicesに代入　viewで使う
      @choices = session[:choices][@index.to_s]
    else # なかったから再生成（保険）
      incorrect_choices = Question.where.not(id: @question.id)
                                  .order("RANDOM()")
                                  .limit(2)
                                  .pluck(:description)
      # 毎回 order("RANDOM()") すると、選択肢の順番が問題表示のたびに変わってしまうため
      # 一度作った選択肢はセッションに固定しておきたい。
      @choices = (incorrect_choices + [@question.description]).shuffle
      session[:choices][@index.to_s] = @choices
    end
      
    # そもそもsessionで「各問題に対してユーザーが何を選んだか」を配列の形で保存
    # session[:answers] = ["意味A", "意味B", nil, "意味C", ...]　session[:answers][1] → 2問目の回答(nilは未回答)
    # [@index]が今何問目かだから、これは「現在の問題に対するユーザーの回答（または 未回答nil）」
    @current_answer = session[:answers][@index]
    # 問題データの類義語からsimilar_wordカラムを取得
    @similar_words = @question.question_similar_words.pluck(:similar_word)
  
    # 通常遷移かAjaxかに応じて適切なレスポンスを返す部分
    respond_to do |format|
      format.html # 通常の画面遷移
      format.js   # question_session.js.erb を探し、JSで動的に問題を表示更新する（Ajax）
    end
  end
  

  # ユーザーの回答アクション（Ajax対応版）
  def submit_session_answer
    index = params[:index].to_i # 今回答えた問題が何問目か（0スタート）を受け取る
    answer = params[:answer] # 選択された選択肢（ユーザーの解答）
    session[:answers][index] = answer if session[:answers] # 該当の問題番号に、選んだ回答を保存（セッション）
  
    # まだ次の問題があるかチェック、10問なら index は最大で9。つまり index + 1 < 10 のときは次の問題がある    
    if index + 1 < session[:flashcard_questions].size #sizeじゃなくて10でいいかも
  
      @index = index + 1 # 現在の問題番号がindexなので、+1したら次の問題番号になる

      # session[:flashcard_questions] は、セッション開始時に保存したquestion_idが並んだ配列［5, 3, 8...］
      # その配列のインデックス番号（次の問題番号）を指定してfind、つまり次に出すべき問題のquestion_id
      @question = Question.find(session[:flashcard_questions][@index])

      # その問題番号に対応する選択肢（3つ）をセッションから取り出す（.to_sで文字列に変換してアクセス）
      @choices = session[:choices][@index.to_s]

      @current_answer = session[:answers][@index] # もし既に解答済みならその回答（再表示の時用）
      @similar_words = @question.question_similar_words.pluck(:similar_word) #類義語の配列
      Rails.logger.debug("セッションの回答内容: #{session[:answers]}")
      respond_to do |format|
        format.js   # submit_session_answer.js.erb を探す
      end
    else # 最後の問題だった場合(10<10)はJSを直接返してresult_session.html.erbへ遷移
      respond_to do |format|
        #format.js { render js: "window.location.href='#{result_session_flashcards_path}'" }
        format.js { render js: "window.location.href='#{view_context.result_session_flashcards_path}'" }
      end
    end
  end


  # 採点前確認ページ
  def result_session

  #これは普通に中断抜きでも適応されちゃうから消した
  # 回答が10問あるかどうかをチェック
  #answered_all = session[:answers]&.size == 10
  # 採点済みかどうか（=中断されたか）
  #is_not_graded = session[:graded] != true
  # 採点済みかつ未回答なら再開ページにリダイレクト
  #unless answered_all && is_not_graded
    #redirect_to resume_flashcard_path(session[:current_flashcard_id]) and return
  #end

    # 結果ページであっても、中断状態を確認
  #if session[:interrupted]
    # 中断した問題から再開する
    #redirect_to resume_flashcards_path
  #else
    # セッション開始時、選出された10問のquestion_id配列を取得
    @question_ids = session[:flashcard_questions]
  
    #セッション消えた時用
    if @question_ids.blank?
      redirect_to flashcards_path, alert: "問題情報が見つかりませんでした。" and return
    end
  
    # 
    @user_answers = session[:answers] || {}
    @questions = Question.find(@question_ids)
  
    @results = @questions.each_with_index.map do |q, i|
      {
        question: q,
        answer: @user_answers[i]
      }
    end
  end


  # 単語帳セッション中の「中断する」で単語帳セッション一覧に戻る
  def interrupt
    Rails.logger.debug("Answers in session: #{session[:answers].inspect}")
    flashcard_id = session[:current_flashcard_id]
    return redirect_to flashcards_path, notice: "セッションがありません" unless flashcard_id

    flashcard = current_user.flashcards.find(flashcard_id)
    question_ids = session[:flashcard_questions]
    answers = session[:answers]

    Rails.logger.debug("Question IDs: #{question_ids.inspect}")
  Rails.logger.debug("Answers array: #{answers.inspect}")

    question_ids.each_with_index do |question_id, index|
      answer = answers[index]
      FlashcardQuestion.find_or_initialize_by(flashcard: flashcard, question_id: question_id).tap do |fq|
        fq.user_answer = answer
        fq.save!
      end
    end

    Rails.logger.debug("Answer for question #{question_ids}: #{answers}")


    # 中断後はセッションをクリア
    session[:flashcard_questions] = nil
    session[:answers] = nil
    session[:current_flashcard_id] = nil

    redirect_to flashcards_path, notice: "中断しました。"
  end

  # 中断した単語帳セッションを復元して再開
  def resume
    #flashcard = current_user.flashcards.find(params[:id])
    flashcard = current_user.flashcards.find_by(id: params[:id])

    unless flashcard
    redirect_to flashcards_path, alert: "問題情報が見つかりません。" and return
    end

    flashcard_questions = flashcard.flashcard_questions.includes(:question)
   
    if flashcard_questions.empty?
      redirect_to start_session_flashcards_path, notice: "セッションが見つかりませんでした。"
      return
    end
  
    # 問題と回答を再構成
    session[:flashcard_questions] = flashcard_questions.map(&:question_id)
    session[:answers] = flashcard_questions.map(&:user_answer)
    session[:current_flashcard_id] = flashcard.id

    Rails.logger.debug("セッションの状態: #{session[:answers]}")

    # 最初の未回答の問題に遷移（または最初に戻る）
    # first_unanswered = session[:answers].index(nil) || 0
    # redirect_to question_session_flashcards_path(index: first_unanswered)

    if session[:answers].all? { |answer| answer.present? } && !session[:interrupted]
      # 中断処理を行い、続きから再開できるようにフラグを設定
      session[:interrupted] = true
      redirect_to question_session_flashcards_path(index: session[:answers].size) # 次の問題（再開位置）から始める
    else
      # 最初の未回答の問題に遷移
      first_unanswered = session[:answers].index(nil)
      if first_unanswered
        redirect_to question_session_flashcards_path(index: first_unanswered)
      else
      # 全問回答済みの場合、結果画面に遷移
        redirect_to result_session_flashcard_path(flashcard)
        # redirect_to result_session_flashcards_path
        # sつければ直るが、question_sessionのほうで二問目に遷移しなくなる
      end
    end
  end


  # 採点結果
  def result
      flashcard = current_user.flashcards.find(params[:id])
      flashcard_questions = flashcard.flashcard_questions.includes(:question)
    
      @results = flashcard_questions.map do |fq|
        {
          question: fq.question,
          user_answer: fq.user_answer,
          correct_answer: fq.question.description,
          correct_answered: fq.correct
        }
      end
    
      @correct_count = @results.count { |r| r[:correct_answered] }
      @total_count = @results.size
  end


  #採点を確定させる（result_sessionからsessionへ）
  def finalize_session
    flashcard_id = session[:current_flashcard_id]
    @flashcard = current_user.flashcards.find(session[:current_flashcard_id])
    question_ids = session[:flashcard_questions]
    answers = session[:answers]
    
  
    if question_ids.blank? || answers.blank? || flashcard_id.blank?
      redirect_to flashcards_path, alert: "セッションが見つかりませんでした。" and return
    end
  
    flashcard = current_user.flashcards.find(flashcard_id)
  
    # 既存の回答がある場合は削除（再採点の可能性を考慮）
    flashcard.flashcard_questions.destroy_all
  
    score = 0
  
    question_ids.each_with_index do |question_id, index|
      question = Question.find_by(id: question_id)
      user_answer = answers[index]
  
      is_correct = question.present? && user_answer.to_s.strip.downcase == question.description.strip.downcase
      score += 1 if is_correct
  
      flashcard.flashcard_questions.create!(
        question_id: question_id,
        user_answer: user_answer,
        correct: is_correct
      )
    end
  
    flashcard.update!(correct_count: score, score: score)
  
    # セッションをクリア（採点完了したので）
    session[:flashcard_questions] = nil
    session[:answers] = nil
    session[:current_flashcard_id] = nil

    session[:choices] = nil

    session[:graded] = true
  
    redirect_to result_flashcard_path(@flashcard, from_session: true)
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


  def ranking
    # ユーザーの保持する最高成績
    @best_flashcard = current_user.flashcards.where.not(score: nil).order(score: :desc, created_at: :asc).first
  
    # ランキング表示用：各ユーザーのベストスコアを計算
    @rankings = User.includes(:flashcards).map do |user|
      best = user.flashcards.where.not(score: nil).order(score: :desc, created_at: :asc).first
      if best.present?
        {
          user: user,
          score: best.score,
          accuracy: ((best.score.to_f / 10) * 100).round
        }
      end
    end.compact.sort_by { |r| -r[:score] }
  
    # お疲れ様メッセージ表示用
    if @best_flashcard.present?
      @user_data = {
        total_questions: 10,
        total_correct: @best_flashcard.score,
        accuracy: ((@best_flashcard.score.to_f / 10) * 100).round
      }
  
      # @rankings から current_user のランクを取得
      index = @rankings.find_index { |r| r[:user].id == current_user.id }
      @user_rank = index ? index + 1 : "ランク外"
    end
  
    # 結果ページから遷移したときだけ自分のデータを表示
    @show_user_data = params[:from_result] == "true"
   
  end
end
#   # Rankingページ用
#   def ranking
#     # 完了済みセッションのみ取得
#     # correct_count が nil ではない(.where.not) = 採点済みのセッション
#     completed_flashcards = Flashcard.where.not(correct_count: nil)
  
#     # ユーザーごとにセッション数と正解数を集計し、user_statsに
#     # .group(:user_id)で採点済みセッションをuser_id＝ユーザーごとにまとめる
#     # .select
#     user_stats = completed_flashcards.group(:user_id).select(
#       # グループ化のキー（ユーザーごと）を結果に含める
#       :user_id,
#       # 採点済みセッションの正解数の合計(SUM)をtotal_correctという名前で取得
#       'SUM(correct_count) AS total_correct',
#       # COUNT(*)は取得された行の数を返す=採点済みのセッションの数 をsession_countという名前で取得
#       'COUNT(*) AS session_count'
#     )
#     # ↑SQLとして見ると
#     #SELECT user_id, SUM(correct_count) AS total_correct, COUNT(*) AS session_count
#     #FROM flashcards
#     #WHERE correct_count IS NOT NULL
#     #GROUP BY user_id

#     # こうゆうイメージのオブジェクトの配列が今user_statsに
#     #[<#ActiveRecord object user_id: 1, total_correct: 27, session_count: 3>,
#     # <#ActiveRecord object user_id: 2, total_correct: 13, session_count: 2>]


#     # 全ユーザーの情報を一括取得（処理を良くするため必要）
#     # user_statsの中のuser_idを.map(&:user_id)で取り出し、.where(id: [...])で対象ユーザーのレコードをまとめて取得
#     users = User.where(id: user_stats.map(&:user_id))
#     # 毎回User.findしない為にシンボルで指定した値(:id)をキーにハッシュ化
#     user_map = users.index_by(&:id)
  

#     # 正解率計算 + ソート
#     # それぞれのstatは「ある1人のユーザーの正解数とセッション数」に関する情報
#     # .mapで1人ずつ処理して、必要な情報を持ったハッシュに整形
#     @rankings = user_stats.map do |stat|
#       {
#         # 該当ユーザーを取得
#         user: user_map[stat.user_id], #User.find(stat.user_id)
#         # 正解数...SQLでSUM(correct_count)した値を.to_i して整数化
#         total_correct: stat.total_correct.to_i,
#         # 合計問題数...セッション数×10　これも.to_i して整数化
#         total_questions: stat.session_count.to_i * 10,
#         # 正解率(%)...total_correct.to_fで整数から小数へ（計算結果で小数点出す為）
#         # .round(2)で小数点2位まで表示
#         # 例: (74/18*10)*100=7400/180=41.11(%)
#         accuracy: (stat.total_correct.to_f / (stat.session_count.to_i * 10) * 100).round
#       }
#     # ハッシュを正解率の高い順にソート（降順）ここでは:accuracyをキーにしている
#     end.sort_by { |r| -r[:accuracy] }
  
#     # 現在のユーザーの成績と順位（viewで使う）
#     if current_user
#       # @rankingsからuserキーの値がcurrent_userと一致する要素（＝ログイン中のユーザーの成績)を探す
#       current_user_data = @rankings.find { |r| r[:user] == current_user }
#       # 順位用...indexメソッドで正解率順に整理されたハッシュ@rankingsの中からログインしてるユーザー（要素）を探したい
#       # 要素が最初の要素から何番目にあるのか整数で返る＝順位が分かる（+1するのはインデックス番号0から始まるから）
#       @user_rank = @rankings.index(current_user_data) + 1 if current_user_data
#       @user_data = current_user_data
#     end
#   end
  
# end

  

    
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
