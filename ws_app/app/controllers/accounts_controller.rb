class AccountsController < ApplicationController
  before_filter :non_html_request
  before_filter :authenticate_admin
  

  def create
    @account = BolideApi::Account.load_with(params[:account])
    if @account.save
      render :nothing=>true
    else
       raise @account.errors.full_messages.join(', ')
    end
  end


  private   
  def authenticate_admin
     authenticate_or_request_with_http_basic("API Login") do |account, key|
       account == 'admin' && key == '1234'
     end
  end
end
