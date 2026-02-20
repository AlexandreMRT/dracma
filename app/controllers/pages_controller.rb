class PagesController < ApplicationController
  skip_before_action :require_login, only: [ :login ]

  def login
    redirect_to root_path if logged_in?
  end
end
