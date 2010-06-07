class Config::TcCompaniesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Compagnies d'estimation")
end
