require File.expand_path('../base', __FILE__)

class MsgWsTest < BaseStreamTest
  def setup
    super
    
    async = true
    set_headers
    EventMachine.run{ 
      after_request do |chunk|
        EM.stop
      end
      put "/q/#{Q1}.xml" 
    }
    
    @account = BolideApi::Account.load_with(:_id=>ACCOUNT)
    @q = BolideApi::Q.load_with(:_id=>Q1, :account=>@account)
    assert @q.saved
  end
  
  def test_broadcast
    send_msg ".*"
    
    # check that the message is found in mq
    assert_equal MSG, @q.read_msg
    
    #check that the stats are upadted
    assert_equal 1, @q.account.sent
    assert_equal 1, @q.account.delivered
  end
  
  def test_direct
    send_msg [Q1]
    
    # check that the message is found in mq
    assert_equal MSG, @q.read_msg
    
    #check that the stats are upadted
    assert_equal 2, @q.account.sent
    assert_equal 2, @q.account.delivered
  end
  
  def test_partial
    send_msg "Q.*"
    
    # check that the message is found in mq
    assert_equal MSG, @q.read_msg
    
    #check that the stats are upadted
    assert_equal 3, @q.account.sent
    assert_equal 3, @q.account.delivered
  end
  
  def test_fail_direct

    msg = create_msg(MSG, "patate")
    after_request do |chunk|
      if !chunk.empty?
        xml = Nokogiri::XML(chunk)
        assert !xml.at_css("warning").nil?   
        assert xml.at_css("error").nil?   
        EM.stop
      end
    end
    
    EventMachine.run{
      post "/msg.xml", msg
    }
  end
  
end