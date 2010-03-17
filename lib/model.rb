models = File.join(File.dirname(__FILE__), 'models')
systems = File.join(File.dirname(__FILE__), 'systems')
require File.join(systems, 'mq')
require File.join(systems, 'in_memory_memcache')
require File.join(systems, 'memcache')
require File.join(models, 'base')
require File.join(models, 'account')
require File.join(models, 'q')
require File.join(models, 'msg')
