require File.expand_path('../../.bundle/environment', __FILE__)
Bundler.require(:default)

require "test/unit"
require "rack/test"
require 'usher'
require 'rack'
require 'memcachedb'
require 'nokogiri'
require 'active_support/time'

require '../lib/config'
require '../lib/model'

server_f =  File.join(File.dirname(__FILE__), '../server')
require File.join(server_f, 'streaming')
require File.join(server_f, 'base_ws')
require File.join(server_f, 'q_ws')
require File.join(server_f, 'msg_ws')
require File.join(server_f, 'parse_user_agent')

ENV['RAILS_ENV'] = "test"

class QWsTest < Test::Unit::TestCase
  include Rack::Test::Methods
  ACCOUNT = "test"
  Q1 = "Q1"
  
  def app
    routes = Usher::Interface.for(:rack) do
      add('/(:account)/(:queue)/(:token)').to(StreamController)
    	add('/q/(:id).xml').to(QWsController)
    	add('/q.xml').to(QWsController)
    	add('/msg.xml').to(MsgWsController)
    end
  end
  
  def setup
    @account = BolideApi::Account.load_with(:_id=>ACCOUNT)
    assert @account.save
  end
  
  def test_create_account
    
    #check that the account is saved in memcache
    @account2 = BolideApi::Account.load_with(:_id=>ACCOUNT)
    assert_equal @account2.api_key, @account.api_key

    #check that the queue vhost for bolide as the account name
    assert @account.vhost_q.pop.match(ACCOUNT)
    
    #check that the stats are created
    assert BolideApi::MemCache.instance.get(@account.delivered_key)
    assert BolideApi::MemCache.instance.get(@account.sent_key)
    assert BolideApi::MemCache.instance.get(@account.concurrent_key)
    
    #check that it was added to #accounts
    accounts = BolideApi::MemCache.instance.get("#accounts");
    assert accounts.include?(ACCOUNT)
  end
  
  def test_create_q
    async = true
    
    after_request do |chunk|
      #check that the request returned valid data
      xml = Nokogiri::XML(chunk)
      
      name = xml.at_css('q')[:id]
      assert_equal Q1, name

      token = xml.at_css('q token').content
      assert token

      expire_on = xml.at_css('q expire_on').content
      assert expire_on
      assert DateTime.parse(expire_on) > DateTime.now

      msg_count = xml.at_css('q msg_count').content
      assert msg_count

      #now check that the q was really created
      @account = BolideApi::Account.load_with(:_id=>ACCOUNT)
      assert @account.qs.include?(Q1)
      
      EM.stop
    end
    
    set_headers
    
    EventMachine.run{ put "/q/" + Q1 + ".xml" }
  end
  
  
  def set_headers
    now = DateTime.now.to_s
    header 'X-Bol-Date',now
    header 'X-Bol-Authentication', auth_key(now)
    header 'Content-Type','application/xml'
  end
  
  def auth_key(now)
    auth_key_prev = 'Account:' + @account._id + '\n' + 'Api-Key:' + @account.api_key + '\n' + 'X-Bol-Date:' + now
    auth_key = Digest::MD5.hexdigest(auth_key_prev)
    @account._id + ':' + auth_key
  end
  
end
