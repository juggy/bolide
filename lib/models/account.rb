require File.expand_path("../account/account_statistics.rb", __FILE__)

module BolideApi
  
  class Account < Base
    include AccountStatistics
    attr_accessor :_id, :qs, :month_start, :api_key 
    validates_presence_of :_id, :api_key
    
    def self.accounts
      accounts = MemCache.instance.get '#accounts' do
        []
      end
      accounts.collect! do |a|
        Account.load_with(:_id=>a)
      end
    end
    
    def after_initialize
      @qs = [] if @qs.nil?
      @api_key = UUID.generate
    end
  
    def vhost
      @vhost = MQ.open("/" + @_id) unless @vhost
      @vhost
    end
    
    def key
      @_id
    end
  
    def marshal_dump
      {
        :id=>@_id,
        :api_key=>@api_key,
        :qs=>@qs,
        :month_start=>@month_start,
        :saved=>@saved
      }
    end
    
    def marshal_load(data)
      @_id = data[:id]
      @api_key = data[:api_key]
      @qs = data[:qs]
      @month_start = data[:month_start]
      @saved = data[:saved]
    end
  
    #create vhost & counters
    def after_create
      #create vhost on rabbitmq sending a message on the bolide/vhost queue
      vhost_q.publish(YAML::dump({"add_vhost"=>"/" + @_id}))
      
      #concurrent connections
      MemCache.instance.set(delivered_key, 0, 0, true)
      MemCache.instance.set(sent_key, 0, 0, true)
      MemCache.instance.set(concurrent_key, 0, 0, true) 
      
      #add to the account array
      update_accounts
    end
    
    def update_accounts
      
      account_ids = MemCache.instance.get('#accounts') do 
        []
      end
      account_ids << @_id
      MemCache.instance.set('#accounts', account_ids)   
    end
  
    #delete vhost
    def after_destroy
      #create vhost on rabbitmq sending a message on the bolide/vhost queue
      vhost_q.publish(YAML::dump({"delete_vhost"=>"/" + @_id}))
    end

    def vhost_q
      @amqp_vhost = MQ.open("/bolide") unless @amqp_vhost
      @amqp_vhost.queue('vhost', :type=>'durable')
    end
  
  end
end