module BolideApi
  
  module AccountStatistics
      
    #accessors
    
    def sent
      Integer(MemCache.instance.get(sent_key, true))
    end
    
    def delivered
      Integer(MemCache.instance.get(delivered_key, true))
    end
    
    def concurrent
      Integer(MemCache.instance.get(concurrent_key, true))
    end
      
    #update with atomic methods
    def up_sent
      MemCache.instance.increment sent_key
    end

    def up_delivered
      MemCache.instance.increment delivered_key
    end

    def up_concurrent
      MemCache.instance.increment concurrent_key
    end

    def down_concurrent
      MemCache.instance.decrement concurrent_key
    end
    
  protected
  #keys
    def concurrent_key
      "#" + key + '/live/concurrent'
    end

    def sent_key
      "#" + key + '/live/sent'
    end

    def delivered_key
      "#" + key + '/live/delivered'
    end
    
  end
  
end