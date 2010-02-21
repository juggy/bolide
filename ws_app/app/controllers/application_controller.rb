require 'digest/md5'

class ApplicationController < ActionController::Base
  rescue_from Exception, :with => :catch_all_exceptions
    
  protected
  def non_html_request
    render :status=>500, :text=>'HTML is not supported' if request.format == Mime::HTML
  end
  
  def authenticate  
    
    #check header for account and api_key 
    auth = request.env['HTTP_X_BOL_AUTHENTICATION']
    if(auth)
      logger.info "Auth: " + auth
      parts = auth.split(':')
      auth_key = parts[1]
      @account = BolideApi::Account.load_with( :_id => parts[0])
      if(@account.saved)
        date = request.env['HTTP_X_BOL_DATE']
        gen_auth_key_prev = 'Account:' + @account._id + '\n' + 'Api-Key:' + @account.api_key + '\n' + 'X-Bol-Date:' + date
        gen_auth_key = Digest::MD5.hexdigest(gen_auth_key_prev)
        return if(gen_auth_key == auth_key)
      end
    end
    raise "Invalid Authentication"
  end
  
  def catch_all_exceptions(exception)
    logger.error exception
    logger.error exception.backtrace.join("\n")
    
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.error exception.message
    
    respond_to do |f|
      f.xml{ render :status=>response_code_for_rescue(exception), :xml=>xml.target!}
    end
  end
end
