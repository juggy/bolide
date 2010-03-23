require 'singleton'

class Hash
  def get(key)
    val = self[key]
    val = yield if (val.nil? && block_given?)
    self[key] = val
  end
end

module BolideApi
  
  class InMemoryQueue
    def initialize
      @q = []
    end
    def publish(value)
      #p "PUB " + value
      @q << value
    end
    def message_count
      @q.length
    end
    def pop
     # p "POP " + @q.inspect
      @q.pop
    end
  end

  class InMemoryMQ
    def initialize
      @queues = {}
    end
    
    def queue(qname)
      @queues.get(qname) do
        #p "CREATE Q " + qname
        InMemoryQueue.new
      end
    end
  end

  class MQ
    
    @@channels = {}
    
    attr_accessor :vhost, :amqp
    
    def []=(qname, pub_value)
       self[qname].publish pub_value
    end

    def [](qname)
      @qs.get(qname) do 
        @amqp.queue(qname)
      end
    end
    
    def queue(qname, opts)
       @qs.get(qname) do 
         @amqp.queue(qname)
       end
    end
    
    def self.open(vhost)
      @@channels.get(vhost) do
        MQ.new(vhost)
      end
    end
    
    def initialize(vhost)
      @qs = {}
      @vhost = vhost
      
      if ENV['RAILS_ENV'] == 'test'
        #p "CREATE HOST " + vhost
        @amqp = InMemoryMQ.new
      else
        @amqp = Carrot.new(AmqpConnection::connection.merge!({:vhost=> vhost})) 
      end
    end
    
  end
end