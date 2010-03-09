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

require 'daemons'
require 'logger'


ENV['RAILS_ENV'] = 'development'

EventMachine::run {
  
  require File.expand_path("../statistics/statistics", __FILE__)
  require File.expand_path("../vhost/vhost", __FILE__)
  
}
