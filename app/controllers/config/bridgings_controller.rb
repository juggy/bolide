class Config::BridgingsController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Types de pontage")
end
