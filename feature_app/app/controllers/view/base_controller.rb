class View::BaseController < ApplicationController

  layout 'public'

  def index
    if !signed_in?
      redirect_to what_url
      return
    end
  end

  def what
    @user = ::User.new(params[:user])
  end
  
  def how
    @user = ::User.new(params[:user])
  end
  
  def api
    @user = ::User.new(params[:user])
  end

end
