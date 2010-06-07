class Config::EmployeeLevelsController < ResourceController::Base
  include Config::ConfigController
  simple_config _("niveau compétence employé")
end
