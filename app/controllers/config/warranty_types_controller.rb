class Config::WarrantyTypesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Types de garantie")
end
