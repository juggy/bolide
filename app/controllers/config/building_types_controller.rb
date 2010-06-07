class Config::BuildingTypesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Type d'immeubles")
end
