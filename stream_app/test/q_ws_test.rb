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

class HelloWorldTest < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    routes = Usher::Interface.for(:rack) do
      add('/(:account)/(:queue)/(:token)').to(StreamController)
    	add('/q/(:id).xml').to(QWsController)
    	add('/q.xml').to(QWsController)
    	add('/msg.xml').to(MsgWsController)
    end
  end
  
  def test_create_account
    
  end
  
end