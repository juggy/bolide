
begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

Bundler.require(:default)

require File.expand_path("../../../lib/config", __FILE__)
require File.expand_path("../../../lib/model", __FILE__)
require 'eventmachine'
require 'logger'

logger = Logger.new(File.expand_path("../../log/statistics.log", __FILE__), 'monthly')

EventMachine::run {
  EventMachine::PeriodicTimer.new(10) do

    BolideApi::Account.accounts.each do |a|
      logger.info( {:for=>a._id, 
                  :sent=>a.sent, 
                  :delivered=>a.delivered, 
                  :concurrent=>a.concurrent})
    end
  end
}