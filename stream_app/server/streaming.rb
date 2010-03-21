require 'carrot'
require 'cramp'
require 'cramp/controller'
require 'newrelic_rpm'
require 'new_relic/agent/instrumentation/controller_instrumentation'
  
class String
  def escape_single_quotes
    self.gsub(/'/, "\\\\'")
  end
end

class StreamController < Cramp::Controller::Action
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  
  before_start :verify_client_token
  periodic_timer :send_data, :every => 0.3
  periodic_timer :update_expire, :every => 60
  keep_connection_alive
  #periodic_timer :close_connection, :every => 10

  
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
    msgs = []
    
    msg = @q.read_msg
    while(msg)
      msgs << msg.escape_single_quotes
      msg = @q.read_msg
    end
    if(!msgs.empty?)
      render(jsonp? ? jsonp( msgs.inspect ) : msgs.inspect)
      close_connection
    end
  end
  
  def update_expire
    @q.reset_expiration
    @q.save(false)
  end

  def close_connection
    @q.account.down_concurrent
    update_expire
    
    finish
  end
  
  def jsonp?
    !request.params['jsonp'].nil?
  end

  def jsonp(data)
    "Bolide.MSIECallback('" + data + "');"
  end
  
  add_transaction_tracer :verify_client_token, :category => :rack, :name => 'stream'
  add_transaction_tracer :send_data, :category => :rack, :name => 'stream'
end
