class User < ActiveRecord::Base
  include Clearance::User
  
  alias_method :real_confirm_email!, :confirm_email!
  
  def confirm_email!
    #create account
    if !stream_account.save
       raise @stream_account.errors.full_messages.join(', ')
    end
    
    #confirm the email
    real_confirm_email!
  end
  
  def stream_account
    @stream_account = BolideApi::Account.load_with(:_id=>account) unless @stream_account
    @stream_account
  end
  
  def api_key
    stream_account.api_key
  end
  
end
