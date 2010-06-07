class Config::CompanyCategoriesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Catégories de compagnie")
end
