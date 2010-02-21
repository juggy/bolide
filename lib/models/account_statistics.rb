module BolideApi
  
  module AccountStatistics
      
    #accessors
    
    def sent
      MemCache.instance.get sent_key
    end
    
    def delivered
      MemCache.instance.set delivered_key
    end
    
    def concurrent
      MemCache.instance.set concurrent_key
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
      key + '/live/concurrent'
    end

    def sent_key
      key + '/live/sent'
    end

    def delivered_key
      key + '/live/delivered'
    end
    
  end
  
end