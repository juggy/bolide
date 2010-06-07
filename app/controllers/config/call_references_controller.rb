class Config::CallReferencesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Références de demandes")
end
