class Config::CallTypesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Type de demande")
end
