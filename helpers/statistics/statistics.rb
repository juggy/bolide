require File.expand_path("../../../lib/config", __FILE__)
require File.expand_path("../../../lib/model", __FILE__)
require 'eventmachine'

logger = Logger.new(File.expand_path("../../log/statistics.log", __FILE__), 'monthly')

EventMachine::PeriodicTimer.new(10) do

  BolideApi::Account.accounts.each do |a|
    logger.info( {:for=>a._id, 
                :sent=>a.sent, 
                :delivered=>a.delivered, 
                :concurrent=>a.concurrent})
  end
end