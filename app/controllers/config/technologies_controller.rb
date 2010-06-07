class Config::TechnologiesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Technologies")
end
