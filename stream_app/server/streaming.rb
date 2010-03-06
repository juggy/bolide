require 'carrot'
require 'cramp'
require 'cramp/controller'

class String
  def escape_single_quotes
    self.gsub(/'/, "\\\\'")
  end
end

class StreamController < Cramp::Controller::Action
  before_start :verify_client_token
  periodic_timer :send_data, :every => 1
  periodic_timer :close_connection, :every => 10

  def verify_client_token
    
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
    [200, {'Content-Type' => 'application/json', 
           'Access-Control-Allow-Origin'=>'*',
           'Access-Control-Allow-Headers'=>'x-prototype-version,x-requested-with,X-Prototype-Version, X-Requested-With, Accept',
           'Access-Control-Allow-Methods'=>'GET'}]
  end

  def send_data
    if request.request_method == 'OPTIONS'
      finish
    end
    
    msg = @q.read_msg
      
    while(!msg.nil?)
      render [ jsonp? ? jsonp( msg ) : msg]
      msg = @q.read_msg
    end
    
    finish if jsonp?
    
    # render [jsonp? ? jsonp( "ms'g" ) : "msg"]
    #     finish if jsonp?
  end

  def close_connection
    @q.account.down_concurrent if @q
    finish
  end
  
  def jsonp?
    !request.params['jsonp'].nil?
  end

  def jsonp(data)
    "Bolide.MSIECallback('" + data.escape_single_quotes + "');"
  end
end
