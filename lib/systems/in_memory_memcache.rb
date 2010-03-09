require 'singleton'

module BolideApi
  
  class InMemoryMemCache < Hash
    def get(key)
      raise  Memcached::NotFound if !self.key? key
      self[key]
    end
    
    def set(key, value)
      self[key] = value
    end
    
    def increment(key)
      v = self[key];
      self[key] = v + 1
    end
    
    def increment(key)
      v = self[key];
      self[key] = v - 1
    end
  end
end