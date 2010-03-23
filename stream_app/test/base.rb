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


class BaseStreamTest  < Test::Unit::TestCase
  include Rack::Test::Methods
  ACCOUNT = "test"
  Q1 = "Q1"
  MSG = "HELLO"
  
  def app
    routes = Usher::Interface.for(:rack) do
      add('/(:account)/(:queue)/(:token)').to(StreamController)
    	add('/q/(:id).xml').to(QWsController)
    	add('/q.xml').to(QWsController)
    	add('/msg.xml').to(MsgWsController)
    end
  end
  
  def test_nothing
    
  end
  
  def setup
    @account = BolideApi::Account.load_with(:_id=>ACCOUNT)
    assert @account.save
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
   
   def create_msg(body, qs)
     xml = Nokogiri::XML::Builder.new do |xml|
       xml.msg do
         if qs.kind_of?(String)
           xml.qs :select=>qs
         elsif qs.kind_of?(Array)
           xml.qs do
             qs.each do |q|
               xml.q q
             end
           end
         end
         xml.body do
           xml.cdata body
         end
       end
     end
     xml.to_xml.to_s
   end
  
   def send_msg q

     msg = create_msg(MSG, q)

     after_request do |chunk|
       #read xml
       xml = Nokogiri::XML(chunk)
       assert xml.at_css("warning").nil?
       assert xml.at_css("error").nil?
       EM.stop
     end

     EventMachine.run{
       post "/msg.xml", msg
     }
   end
end