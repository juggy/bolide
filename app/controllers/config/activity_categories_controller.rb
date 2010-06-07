class Config::ActivityCategoriesController < ResourceController::Base
  include Config::ConfigController
  simple_config _("Catégories d'activités")
end
