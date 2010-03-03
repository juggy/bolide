require 'yaml'

class AmqpConnection
  @@connection = YAML.load_file(File.join(File.dirname(__FILE__), 'amqp.yml')) 
  def self.connection
    @@connection[ENV['RAILS_ENV']]
  end
end