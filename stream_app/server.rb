#! /opt/local/bin/ruby

require 'rubygems'
require 'usher'
require 'rack'
require 'memcachedb'

require 'lib/config'
require 'lib/model'

server_f =  File.join(File.dirname(__FILE__), 'server')
require File.join(server_f, 'streaming')
require File.join(server_f, 'parse_user_agent')

routes = Usher::Interface.for(:rack) do
  add('/(:account)/(:queue)/(:token)').to(StreamController)
end

Rack::Handler::Thin.run routes, :Port => 4000