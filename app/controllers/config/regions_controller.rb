class Config::RegionsController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Régions")
end