class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      reset_session # ログインの直前に必ずこれを書くこと
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
      remember user
      log_in user
      redirect_to user
    else
      flash.now[:danger] = 'メールアドレス又はパスワードが間違っています'
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to login_path, status: :see_other
  end
end
