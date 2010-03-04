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

require 'mq'
require 'yaml'
require 'daemons'
require 'logger'
require File.expand_path("../../../lib/config/amqp_connection", __FILE__)

logger = Logger.new(File.expand_path("../log/vhost.log", __FILE__), 12, 'monthly')

ENV['RAILS_ENV'] = 'production'

Daemons.run_proc('vhost') do
while true 
  begin
    AMQP.start(AmqpConnection::connection.merge!({:vhost=>'/bolide'})) do
 
      q = MQ.queue('vhost')
  
      q.pop do |msg| 
        unless msg
          EM.add_timer(5){ q.pop }
        else
          msg_obj = YAML::load( msg );
          if msg_obj.has_key?("add_vhost")
            system ("rabbitmqctl add_vhost " + msg_obj["add_vhost"])
            system ("rabbitmqctl set_permissions -p " + msg_obj["add_vhost"] + ' guest \'.*\' \'.*\' \'.*\'')
          end
      
          if msg_obj.has_key?("delete_vhost")
            system ("rabbitmqctl delete_vhost " + msg_obj["delete_vhost"])
          end
      
          #directly check new entries
          q.pop
        end
      end
  
    end
  rescue Exception => e
    #something went wrong
    logger.error "Vhost Error: #{e}"
  end
end
end