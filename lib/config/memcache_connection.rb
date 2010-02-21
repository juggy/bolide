require 'yaml'
require 'memcachedb'

class MemCacheDbConnection
  @@connection = YAML.load_file(File.join(File.dirname(__FILE__), 'memcache.yml')) 
  def self.servers
     @@connection[ENV['RAILS_ENV'] || 'development']['groups']
  end
  
  def self.options
     @@connection[ENV['RAILS_ENV'] || 'development']['options']
  end
  
end