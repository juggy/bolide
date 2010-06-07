class Config::CautionTypesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Caution")
end
