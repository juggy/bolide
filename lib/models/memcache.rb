require 'singleton'

module BolideApi
  class MemCache
    include Singleton
    
    attr_accessor :memcache
    
    def initialize
      if ENV['RAILS_ENV'] == 'test'
        @memcache = InMemoryMemCache.new
      else
        opts = MemCacheDbConnection.options
        @memcache = MemCacheDb.new(MemCacheDbConnection.servers, opts ? opts : {})   
      end
    end
    
    def get(key)
      value = memcache.get(key)
      yield if value.nil?
    end
   
    def increment(key)
      memcache.increment(key)
    end
    
    def decrement(key)
      memcache.decrement(key)
    end
    
    def set(key, value)
      memcache.set(key, value)
    end
    
  end
end