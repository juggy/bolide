class Config::CallSourcesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Source de demandes")
end