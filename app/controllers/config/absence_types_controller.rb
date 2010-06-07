class Config::AbsenceTypesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Types d'absences")
end
