class RegistrationMailer < ApplicationMailer
  def complete_registration(user)
    @user = user
    mail(:subject => "単語帳の新規登録完了のお知らせ", to: user.email)
  end
end