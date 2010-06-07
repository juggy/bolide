class Config::CallCommSourcesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Source de demandes (type de communication)")
end
