class Config::RooferInterventionConditionsController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Conditions déplacements couvreurs")
end
