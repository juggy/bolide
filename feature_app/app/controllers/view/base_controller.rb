class View::BaseController < ApplicationController
  before_filter :bolidify
  before_filter :verify_admin, :only=>[:board]
  layout 'public'

  def index
    if !signed_in?
      redirect_to what_url
      return
    end
  end
  
  def board
    @users = User.find(:all)
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

  private
  
  def bolidify
    @bolide = session[:bolide]
    @q = session[:q]
    
    if @bolide.nil?
      @bolide = Bolide::Account.new("bolide", "2adc61d0-095c-012d-0076-404077aa86f5")
      session[:bolide] =  @bolide
    end
    if @q.nil?
      q_name = session[:session_id]
      @q = @bolide.get_q(q_name)
      session[:q] = @q
    end
    @bolide_account = BolideApi::Account.load_with(:_id=>"bolide")
  end
  
  def verify_admin
    if !signed_in? || current_user.email != "julien.guimont@gmail.com"
      redirect_to index_url
    end
  end

end
