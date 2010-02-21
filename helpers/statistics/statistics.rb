require 'rubygems'
require '../../lib/config'
require '../../lib/model'
require 'eventmachine'

EventMachine::PeriodicTimer.new(5) do
  
  BolideApi::Account.accounts.each do |a|
    { :on=>DateTime.now, 
      :sent=>a.sent, 
      :delivered=>a.delivered, 
      :concurrent=>a.concurrent }
  end
end