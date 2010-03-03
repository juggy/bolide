#! /opt/local/bin/ruby

begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

Bundler.require(:default)

require 'usher'
require 'rack'
require 'memcachedb'
require 'nokogiri'
require 'active_support/time'

require '../lib/config'
require '../lib/model'

server_f =  File.join(File.dirname(__FILE__), 'server')
require File.join(server_f, 'streaming')
require File.join(server_f, 'base_ws')
require File.join(server_f, 'q_ws')
require File.join(server_f, 'msg_ws')
require File.join(server_f, 'msg')
require File.join(server_f, 'parse_user_agent')

routes = Usher::Interface.for(:rack) do
  add('/(:account)/(:queue)/(:token)').to(StreamController)
	add('/q/(:id).xml').to(QWsController)
	add('/q.xml').to(QWsController)
	add('/msg.xml').to(MsgWsController)
end

run routes