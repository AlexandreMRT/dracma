class SessionsController < ApplicationController
  skip_before_action :require_login, only: [ :create, :failure ]

  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    if user.save
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in successfully!"
    else
      redirect_to login_path, alert: "Failed to login: #{user.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Logged out successfully!"
  end

  def failure
    redirect_to login_path, alert: "Authentication failed."
  end
end
