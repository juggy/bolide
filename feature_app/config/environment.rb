# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require '../lib/config'
require '../lib/model'

Rails::Initializer.run do |config|

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem "thoughtbot-clearance", :lib => 'clearance', :source => 'http://gems.github.com/', :version => '0.6.9'
  config.gem 'rubaidh-google_analytics', :lib => 'rubaidh/google_analytics', :source => 'http://gems.github.com'
  # Clearance
  DO_NOT_REPLY = "donotreply@jguimont.com"

  config.gem "memcachedb-client"
  config.gem "carrot"
  config.gem "uuid"
  config.gem "validatable"
  
  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

Rubaidh::GoogleAnalytics.tracker_id   = 'UA-13210481-1'
Rubaidh::GoogleAnalytics.domain_name  = 'jguimont.com'
Rubaidh::GoogleAnalytics.environments = ['production']

ExceptionNotifier.exception_recipients = %w(julien.guimont@gmail.com)