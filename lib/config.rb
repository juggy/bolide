config_f =  File.join(File.dirname(__FILE__), 'config')
require File.join(config_f, 'amqp_connection')
require File.join(config_f, 'memcache_connection')
