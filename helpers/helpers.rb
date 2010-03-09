begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

Bundler.require(:default)

require 'daemons'
require 'logger'

ENV['RAILS_ENV'] = 'production'

Daemons.run("statistics/statistics.rb", :app_name=>'bstat') if ARGV[1] == "bstat"
Daemons.run("vhost/vhost.rb", :app_name=>'bhost') if ARGV[1] == "bhost"
  
# 
#   EventMachine::run {
#     require File.expand_path("../statistics/statistics.rb", __FILE__)
#     require File.expand_path("../vhost/vhost.rb", __FILE__)
#   
#   }
#   
# }
