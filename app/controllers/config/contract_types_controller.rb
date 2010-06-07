class Config::ContractTypesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Type d'ententes")
end
