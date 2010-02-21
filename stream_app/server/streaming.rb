require 'carrot'
require 'cramp'
require 'cramp/controller'

class StreamController < Cramp::Controller::Action
  before_start :verify_client_token
  periodic_timer :send_data, :every => 1
  periodic_timer :close_connection, :every => 10

  def verify_client_token
    @user_agent = ParseUserAgent.new(request.env['HTTP_USER_AGENT'])
    @q = BolideApi::Q.load_with(:_id=>params[:queue], :account_id=>params[:account])
    
    if !@q.valid_token?(params[:token])
      halt 500, {'Content-Type' => 'text/plain'}, "Invalid Queue Token"
      
    elsif DateTime.now > @q.expire_on 
      halt 500, {'Content-Type' => 'text/plain'}, "Queue Expired"
      
    else
      @q.account.up_concurrent
      yield
    end
    
  end

  def respond_with
    content_type = params[:format] == 'xml' ? 'application/xml' : 'application/json'
    [200, {'Content-Type' => content_type}]
  end

  def send_data
    msg = @q.read_msg
   
    while(!msg.nil?)
      render [msg]
      msg = @q.read_msg
    end
    finish if @user_agent.browser = 'MSIE'
  end

  def close_connection
    @q.account.down_concurrent if @q
    finish
  end

end
