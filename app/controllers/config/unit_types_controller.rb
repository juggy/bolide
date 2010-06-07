class Config::UnitTypesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Types d'unités")
end
