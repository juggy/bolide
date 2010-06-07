class Config::BuildingCategoriesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Catégories d'immeuble")
end
