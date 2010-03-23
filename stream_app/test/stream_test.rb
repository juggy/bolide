require File.expand_path('../base', __FILE__)

class StreamTest < BaseStreamTest
  
  def test_invalid_token
    async = true
    
    after_request do |chunk|
      assert_equal "Invalid Queue Token", chunk
      EM.stop
    end
    
    EventMachine.run{
      get "/invalid/queue/token"
    }
    
  end
  
  def test_receive
    async = true
    set_headers
    
    EventMachine.run{ 
      after_request do |chunk|
        EM.stop
      end
      put "/q/#{Q1}.xml" 
      send_msg ".*"
    }
    
    @account = BolideApi::Account.load_with(:_id=>ACCOUNT)
    @q = BolideApi::Q.load_with(:_id=>Q1, :account=>@account)
    
    after_request do |chunk|
      assert_equal [MSG].inspect, chunk
      #assert_equal 1, @account.concurrent
      EM.stop
    end
    
    EventMachine.run{
      get "#{@account._id}/#{@q._id}/#{@q.token}"
    }
    
    #assert_equal 0, @account.concurrent
  end
  
  def test_json
    async = true
    set_headers
    
    EventMachine.run{ 
      after_request do |chunk|
        EM.stop
      end
      put "/q/#{Q1}.xml" 
      send_msg ".*"
    }
    
    @account = BolideApi::Account.load_with(:_id=>ACCOUNT)
    @q = BolideApi::Q.load_with(:_id=>Q1, :account=>@account)
    
    after_request do |chunk|
      assert_equal "Bolide.MSIECallback('#{[MSG].inspect}');", chunk
      #assert_equal 1, @account.concurrent
      EM.stop
    end
    
    EventMachine.run{
      get "#{@account._id}/#{@q._id}/#{@q.token}?jsonp"
    }
  end
  
end