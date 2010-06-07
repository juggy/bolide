class UserSessionsController < ApplicationController
  skip_before_filter :require_user, :except => [:destroy, :zendesk_authorize]
  
  layout 'login'
  
  def new
    @user_session = UserSession.new
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      # flash[:notice] = "Login successful!"
      redirect_back_or_default "/"
    else
      flash[:notice] = "Veuillez vérifiez votre nom ou mot de passe"
      render :action => :new
    end
  end
  
  def destroy
    current_user_session.destroy
    # flash[:notice] = "Logout successful!"
    redirect_back_or_default login_url
  end
  
  include Zendesk::RemoteAuthHelper
  def zendesk_authorize
    redirect_to zendesk_remote_auth_url( 
      :name => "#{current_user.first_name} #{current_user.last_name}",
      :email => current_user.email,
      :external_id => current_user.id,
      :organization => current_account.subdomain
    )
  end
  
end