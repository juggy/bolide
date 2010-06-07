class Config::WorkTypesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Type de travaux")
end
