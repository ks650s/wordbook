class User < ApplicationRecord
  attr_accessor :remember_token
  before_save { self.email = email.downcase }
  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  has_secure_password
  # 英大文字・小文字・数字すべて含む10文字以上
  validates :password,
  length: { minimum: 10 },
  format: {
    # パスワード用の正規表現について
    # /\A ... \z/は\A：文字列の先、\z：文字列の末尾　つまり文字列全体がこのパターンに一致すること
    # (?=.*[a-z])は.*：任意の文字を0文字以上、[a-z]：英小文字が含まれていることをチェック　つまりどこかに英小文字が1つ以上あること
    # (?=.*[A-Z])はどこかに英大文字が1つ以上あること
    # (?=.*\d)は\d：数字（0〜9）　つまりどこかに数字が1つ以上あること
    # [^\s]+は空白文字以外の文字を1文字以上含む（記号もOK）
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[^\s]+\z/,
    message: "は10文字以上かつ英大文字・小文字・数字をすべて含めてください（空白は含めないでください）"
  }
  
  has_many :questions
  has_many :tags
  has_many :flashcards, dependent: :destroy
  
  # 渡された文字列のハッシュ値を返す
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返す
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続的セッションのためにユーザーをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end
end