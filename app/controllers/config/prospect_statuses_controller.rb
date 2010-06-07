class Config::ProspectStatusesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Statut du prospect")
end
