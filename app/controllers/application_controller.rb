class ApplicationController < ActionController::Base
  include SessionsHelper

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end
  
  def require_login
    logger.debug "=== REQUIRE LOGIN ==="
    logger.debug "session[:user_id]: #{session[:user_id]}"
    logger.debug "current_user: #{current_user.inspect}"

    unless logged_in?
      redirect_to login_path, alert: "ログインしてください。"
    end
  end
end
