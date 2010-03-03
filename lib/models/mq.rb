require 'singleton'
module BolideApi

  class InMemoryMQ
    
    def publish(value)
      #nothing to do
    end
    
    def queue(qname)
      self
    end
    
    def message_count
      0
    end
    
    def pop
      "fake msg"
    end
    
  end

  class MQ
    
    attr_accessor :vhost, :amqp
    
    def []=(qname, pub_value)
       self[qname].publish pub_value
    end

    def [](qname)
      @qs.fetch(qname) do 
        @amqp.queue(qname)
      end
    end
    
    def queue(qname, opts)
       @qs.fetch(qname) do 
         @amqp.queue(qname)
       end
    end
    
    def initialize(vhost)
      @qs = {}
      @vhost = vhost
      
      if ENV['RAILS_ENV'] == 'test'
        @amqp = InMemoryMQ.new
      else
        @amqp = Carrot.new(AmqpConnection::connection.merge!({:vhost=> vhost})) 
      end
    end
    
  end
end