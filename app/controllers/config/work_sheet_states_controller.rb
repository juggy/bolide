class Config::WorkSheetStatesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Status feuille de travail")
end
